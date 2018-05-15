import AVKit
import Vision
import Photos
import Foundation
import Accelerate
typealias SFCallback = (UIImage)->Void
typealias VNRGenerator = ()->VNRequest?
typealias BottleneckCB = (MLFeatureProvider, MLModel)->Void
struct ModelStruct {
    var model: MLModel
    var callback: BottleneckCB
}
enum visionErrors:Error {
   case NoModelError
}
var session:AVCaptureSession?
// Don't know if I want this typealias VNReqMaker = () -> VNRequest
@objc(RHDVisionModule)
class RHDVisionDelegate: RCTEventEmitter, AVCaptureVideoDataOutputSampleBufferDelegate, AVCaptureMetadataOutputObjectsDelegate {
    static var instance:RHDVisionDelegate?
    //MARK: Private Collections
    var sr:[String: [String:VNRequest]] = [:] //Sequence Requests
    var srg:[String:[String:VNRGenerator]] = [:] // Sequence Request Generators
    var srobs:[String:[String:VNDetectedObjectObservation]] = [:]
    var ir:[String:[String:VNRequest]] = [:] // Image Requests - by region
    var irg:[String:[String:VNRGenerator]] = [:] // Image Request Generators - by region
    var sf: [String: SFCallback] = [:] //SaveFrame Callbacks - by region
    var br: [String:[String: [String:ModelStruct]]] = [:] //Bottleneck Requests by bottleneck model (does not require a region, since that is specied in the orignal bottlenecking model)
    var regions: [String: CGRect] = [:] // Identified regions, organized as relative position. Note that "" is reserved for the whole visible field
    //MARK: Private Properties
    var pl:AVCaptureVideoPreviewLayer?
    var connection: AVCaptureConnection?
    var srh = VNSequenceRequestHandler()
    var imageHeight = 0
    var imageWidth = 0
    var doAttachCamera = false
    //MARK: Private Methods
    func resetSRH() {
        srh = VNSequenceRequestHandler()
    }
    override init() {
        super.init()
        RHDVisionDelegate.instance = self
        multiArrays = [:] // Prevent memory leaks
        //Kill previous connections
        if let i = RHDVisionDelegate.instance, let thispl = i.pl {
            thispl.session.outputs.forEach() { o in
                if let os = o as? AVCaptureVideoDataOutput , let _ = os.sampleBufferDelegate {
                    thispl.session.removeOutput(os)
                }
            }
        }
        RHDVisionDelegate.instance = self
    }
    override class func requiresMainQueueSetup() -> Bool {
        return false
    }
    //MARK: Lifecycle management
    
    @objc func start(_ cameraFront: Bool, resolve: RCTPromiseResolveBlock, reject: @escaping RCTPromiseRejectBlock) {
        AVCaptureDevice.requestAccess(forMediaType: AVMediaTypeVideo) { success in
            guard success else { reject("no_permission", "Permission denied for Video Capture", nil); return }
            guard
                let device = AVCaptureDevice.defaultDevice(withDeviceType: .builtInWideAngleCamera, mediaType: AVMediaTypeVideo, position: cameraFront ? AVCaptureDevice.Position.front : AVCaptureDevice.Position.back),
                let input = try? AVCaptureDeviceInput(device: device)
                else { return }
            if let olds = session  {
                olds.inputs.forEach() { i in
                    olds.removeInput(i as! AVCaptureInput)
                }
                olds.outputs.forEach() { o in
                    olds.removeOutput(o as! AVCaptureOutput)
                }
                session = nil
            }
            let s = AVCaptureSession()
            s.addInput(input)
            s.startRunning()
            session = s
            let o = AVCaptureVideoDataOutput()
            o.setSampleBufferDelegate(self, queue: DispatchQueue(label:"RHDVisionDelegateQueue"))
            o.alwaysDiscardsLateVideoFrames = true
            o.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA]
            s.addOutput(o)
            if let conn = o.connection(withMediaType: AVMediaTypeVideo) {
                conn.videoOrientation = deviceOrientationtoAVOrientation(UIDevice.current.orientation)
            }
            if(self.doAttachCamera) {
                RHDVisionCameraViewManager.currentView?.attach(s)
            }
        }
    }
    @objc func stop(_ resolve: RCTPromiseResolveBlock, reject: RCTPromiseRejectBlock) {
        guard let s = session else { resolve(true); return }
        s.stopRunning()
        s.inputs.forEach() { i in
            s.removeInput(i as! AVCaptureInput)
        }
        s.outputs.forEach() { o in
            s.removeOutput(o as! AVCaptureOutput)
        }
        resolve(true)
    }
    @objc func getImageDimensions(_ resolve:RCTPromiseResolveBlock, reject: RCTPromiseRejectBlock) {
        resolve(["height": imageHeight, "width": imageWidth])
    }
    @objc func attachCameraView(_ resolve:RCTPromiseResolveBlock, reject: RCTPromiseRejectBlock) {
        //Look for current vision object
        doAttachCamera = true
        guard let view = RHDVisionCameraViewManager.currentView else { reject("no_view", "No view instantiated", nil); return }
        guard let s = session else { resolve(false); return }
        view.attach(s)
        resolve(true)
    }
    @objc func detachCameraView(_ resolve: RCTPromiseResolveBlock, reject: RCTPromiseRejectBlock) {
        doAttachCamera = false
        RHDVisionCameraViewManager.currentView?.detach()
    }
    var isCameraView: Bool = false
    @objc func cameraIsView(_ newIsCameraView: Bool, resolve: RCTPromiseResolveBlock, reject: RCTPromiseRejectBlock) {
        guard isCameraView == newIsCameraView else { resolve(true); return }
        isCameraView = newIsCameraView
        resolve(true)
    }
    //MARK:Delegate Methods
    func captureOutput(_ output: AVCaptureOutput!, didOutputSampleBuffer sampleBuffer: CMSampleBuffer!, from connection: AVCaptureConnection!) {
        self.connection = connection
        if isCameraView, let v = RHDVisionCameraViewManager.currentView, let ao = v.pl?.connection.videoOrientation { connection.videoOrientation = ao }
        guard sr.count > 0
            || srg.count > 0
            || ir.count > 0
            || irg.count > 0
            || sf.count > 0
            || imageHeight == 0,
            let cvp = CMSampleBufferGetImageBuffer(sampleBuffer)
        else { return }
        
        imageHeight = CVPixelBufferGetHeight(cvp)
        imageWidth  = CVPixelBufferGetWidth(cvp)
        analyzePixelBuffer(cvp, key: "") //Image Analysis as applied to the whole visible region
        regions.forEach() { region, rect in
            guard let _ = sr[region], let _ = srg[region] , let _ = ir[region], let _ = irg[region], let _ = sf[region] else { return }
            guard let slicedCVP = slicePixelBuffer(cvp, toRect: rect) else { return }
            analyzePixelBuffer(slicedCVP, key: region)
        }
    }
    func cutToPreview(_ source: CVPixelBuffer) -> CVPixelBuffer {
        guard let v = RHDVisionCameraViewManager.currentView else { return source }
        let PLSize = v.bounds
        let PLRatio = PLSize.width / PLSize.height
        let sourceHeight = CVPixelBufferGetHeight(source)
        let sourceWidth = CVPixelBufferGetWidth(source)
        let sourceRatio = CGFloat(sourceWidth) / CGFloat(sourceHeight)
        guard let gravity = v.pl?.videoGravity else { return source }
        switch(gravity) {
        case AVLayerVideoGravityResizeAspectFill:
            var newWidth: Int
            var newHeight: Int
            var newTop: Int
            var newLeft: Int
            if PLRatio > sourceRatio {
                //Width is limiting factor, so we fill to total height
                newTop = 0
                newHeight = sourceHeight
                newWidth = Int(CGFloat(sourceWidth) * sourceRatio / PLRatio)
                newLeft = (sourceWidth - newWidth) / 2
            } else {
                newLeft = 0
                newWidth = sourceWidth
                newHeight = Int(CGFloat(sourceHeight) * PLRatio / sourceRatio)
                newTop = (sourceHeight - newHeight) / 2
            }
            return resizePixelBuffer(source, cropX: newLeft, cropY: newTop, cropWidth: newWidth, cropHeight: newHeight, scaleWidth: Int(PLSize.width), scaleHeight: Int(PLSize.height)) ?? source
        case AVLayerVideoGravityResizeAspect:
            var newWidth: Int
            var newHeight: Int
            if PLRatio  > sourceRatio {
                //Width is limiting factor
                newWidth = Int(PLSize.width)
                newHeight = Int(CGFloat(sourceHeight) * (PLSize.width / CGFloat(sourceWidth)))
            } else {
                newHeight = Int(PLSize.height)
                newWidth = Int(CGFloat(sourceWidth) * (PLSize.height / CGFloat(sourceHeight)))
            }
            return resizePixelBuffer(source, cropX: 0, cropY: 0, cropWidth: sourceWidth, cropHeight: sourceHeight, scaleWidth: newWidth, scaleHeight: newHeight) ?? source
        default:
            //Do nothing
            return source
        }
    }
    func analyzePixelBuffer(_ cvp: CVPixelBuffer, key: String) {
        var irs:[VNRequest] = []
        if let i = ir[key] {
            i.forEach() { k, v in
                irs.append(v)
            }
        }
        if let i = irg[key] {
            i.forEach() { k, v in
                if let r = v() { irs.append(r) }
            }
        }
        if irs.count > 0 {
            let irh = VNImageRequestHandler(cvPixelBuffer: cvp, options: [:])
            try? irh.perform(irs)
        }
        if let cb = sf[key] {
            let ci = CIImage(cvPixelBuffer: cvp)
            let i = UIImage(ciImage: ci)
            cb(i)
        }
        var srs:[VNRequest] = []
        if let s = sr[key] {
            s.forEach() { k, v in
                srs.append(v)
            }
        }
        if let s = srg[key] {
            s.forEach() { k, generator in
                if let r = generator() { srs.append(r) }
            }
        }
        if srs.count > 0 {
            try? srh.perform(srs, on: cvp)
        }
    }
    //MARK: SaveFrame Code
    let defaultDisposition:String = "file"
    var savedFrames:[String: UIImage] = [:]
    @objc func saveFrame(_ disposition: String?, region: String, resolve: RCTPromiseResolveBlock, reject: RCTPromiseRejectBlock) {
        sf[region] = { i in
            let d = disposition ?? self.defaultDisposition
            switch(d) {
            case "file":
                guard let d = UIImageJPEGRepresentation(i, 1.0) else { return }
                let u = UUID().uuidString
                let t = URL.init(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(u)
                do {
                    try d.write(to: t)
                    self.sendEvent(withName: "RNVision", body: ["key": "saveFrame", "region": region, "event": "savedFile", "fileURL": t.absoluteString])
                    return
                } catch {
                    return
                }
            case "roll":
                switch PHPhotoLibrary.authorizationStatus() {
                case PHAuthorizationStatus.notDetermined:
                    PHPhotoLibrary.requestAuthorization(){ success in
                        switch PHPhotoLibrary.authorizationStatus() {
                        case PHAuthorizationStatus.denied:
                            return
                        default:
                            UIImageWriteToSavedPhotosAlbum(i, nil, nil, nil)
                            self.sendEvent(withName: "RNVision", body:["region": region, "key": "saveFrame", "event":"savedToRoll"])
                        }
                    }
                case PHAuthorizationStatus.denied:
                    return
                default:
                    UIImageWriteToSavedPhotosAlbum(i, nil, nil, nil)
                    self.sendEvent(withName: "RNVision", body:["region": region, "key": "saveFrame", "event":"savedToRoll"])
                }
            case "memory":
                let u = UUID().uuidString
                self.savedFrames[u] = i
                self.sendEvent(withName: "RNVision", body:["region": region, "key": "saveFrame", "event":"savedToMemory", "savedFrameID": u])
            default:
                return
            }
        }
        resolve(region)
    }
    @objc func removeSaveFrame(_ region:Srtring, resolve:RCTPromiseResolveBlock, reject: RCTPromiseRejectBlock) {
        sf.removeValue(forKey: region)
        resolve(true)
    }
    //MARK:Face Detection
    @objc func detectFaces(_ region: String, resolve: RCTPromiseResolveBlock, reject:RCTPromiseRejectBlock) {
        guard ir[region]?["detectFaces"] == nil else { resolve("RNVFaceDetected"); return }
        if ir[region] == nil { ir[region] = [:] }
        ir[region]!["detectFaces"] = VNDetectFaceRectanglesRequest() { request, error in
            var data:[Any] = []
            guard error == nil else { return }
            guard let r = request.results else {  return }
            r.forEach() { result in
                guard let rs = result as? VNDetectedObjectObservation else {return}
                let bb = rs.boundingBox
                let normalRect = visionRectToNormal(bb)
                data.append(rectToDictionary(normalRect))
                self.sendEvent(withName: "RNVision", body: ["region": region, "key": "RNVFaceDetected", "data":data])
            }
        }
        resolve("RNVFaceDetected");
    }
    @objc func removeDetectFaces(_ region: String, resolve: RCTPromiseResolveBlock, reject: RCTPromiseRejectBlock) {
        guard let _ = ir[region]?["detectFaces"]  else { reject("not_running", "Not running detect faces",nil); return}
        ir[region]?.removeValue(forKey: "detectFaces")
        resolve(true)
    }
    //MARK: Object Tracking
    @objc func trackObject(_ name: String, region: String, dict: [String: Any], resolve: RCTPromiseResolveBlock, reject: RCTPromiseRejectBlock) {
        guard let r = dictionaryToRect(dict) else { reject("no_rectangle", "Dictionary does not represent a usable rectangle", nil); return }
        if srg[region] == nil { srg[region] = [:] }
        if srobs[region] == nil { srobs[region] = [:] }
        let visionRect = normalRectToVision(r)
        let obs = VNDetectedObjectObservation(boundingBox: visionRect)
        srobs[region]![name] = obs
        srg[region]![name] = {
            guard let o = self.srobs[region]?[name] else { return nil }
            let r = VNTrackObjectRequest(detectedObjectObservation: o) {request, error in
                guard
                    error == nil,
                    let newobs = request.results?.first as? VNDetectedObjectObservation
                    else { print("TO Error", error); return }
                let newBox = visionRectToNormal(newobs.boundingBox)
                let oldobsQ = self.srobs[region]![name]
                self.srobs[region]![name] = newobs
                guard let oldobs = oldobsQ else { return }
                //guard newobs.boundingBox != oldobs.boundingBox else { return }
                self.regions[name] = newobs.boundingBox
                self.sendEvent(withName: "RNVision", body: ["key": name, "region": region, "frame": rectToDictionary(newBox), "confidence": newobs.confidence])
            }
            r.preferBackgroundProcessing = true
            r.trackingLevel = .accurate
            return r
        }
        resolve(region)
    }
    @objc func removeTrackObject(_ name: String, region: String, resolve: RCTPromiseResolveBlock, reject: RCTPromiseRejectBlock) {
        srobs[region]?.removeValue(forKey: name)
        resolve(true)
    }
    @objc func removeTrackObjects(_ region: String, resolve: RCTPromiseResolveBlock, reject: RCTPromiseRejectBlock) {
        let keys = srobs[region]?.keys
        srobs[region]?.removeAll()
        resolve(["removedKeys": keys])
    }
    //MARK: CoreML Model Application
    var ms:[String: MLModel] = [:]
    func applyML(_ thisURL: String, field: String, resolve:RCTPromiseResolveBlock, reject:RCTPromiseRejectBlock, cb:@escaping VNRequestCompletionHandler) {
        var origmodel:MLModel? = ms[thisURL]
        if  origmodel == nil {
            guard let modelURL = URL(string: thisURL) else { reject("bad_url", "This is a bad URL: " + thisURL, nil); return  }
            guard let o = try? MLModel(contentsOf: modelURL) else { reject("no_model", "No model at " + thisURL, nil); return }
            ms[thisURL] = o
            origmodel = o
        }
        guard let m = origmodel else { reject("no_model", "Unable to load model at URL " + thisURL, nil); return }
        guard let vnmodel = try? VNCoreMLModel(for: m) else { reject("not_vision_model", "Model is not vision model: " + thisURL, nil); return }
        let r = VNCoreMLRequest(model: vnmodel, completionHandler: cb)
        if ir[field] == nil { ir[field] = [:] }
        ir[field]![thisURL] = r
        resolve(thisURL)
    }
    //Note that resultMax is basically ignored if it is 0 or less
    @objc func applyMLClassifier(_ thisURL: String, field: String, resultMax: Int, resolve:RCTPromiseResolveBlock, reject:RCTPromiseRejectBlock) {
        applyML(thisURL, field: field, resolve: resolve, reject: reject) { request, error in
            guard error == nil, let results = request.results else { return }
            var out:[[String:Any]] = []
            for result in results {
                if let co = result as? VNClassificationObservation {
                    let obj:[String: Any] = ["label": co.identifier, "confidence": co.confidence];
                    out.append(obj)
                    if(resultMax > 0 && ((out.count + 1) > resultMax)) {
                        break;
                    }
                }
            }
            self.sendEvent(withName: "RNVision", body:["region": field, "key": thisURL, "data": out])
        }
    }
    var pixelBuffers:[String:CVPixelBuffer] = [:]
    @objc func applyMLGenerator(_ thisURL: String, field: String, handler: String, resolve: RCTPromiseResolveBlock, reject: RCTPromiseRejectBlock) {
        applyML(thisURL, field: field, resolve: resolve, reject: reject) { request, error in
            guard error == nil, let results = request.results else { return }
            for result in results {
                if let pbo = result as? VNPixelBufferObservation {
                    //OK, let's save this result
                    //Check my handlers
                    if handler == "sendEvent" {
                        self.pixelBuffers[thisURL] = pbo.pixelBuffer;
                        self.sendEvent(withName: "RNVision", body: ["region": field, "key": thisURL])
                    } else if let v = RHDVisionImageViewManager.instance?.views[handler] {
                        v.image = UIImage(ciImage: CIImage(cvPixelBuffer: pbo.pixelBuffer))
                    }
                }
            }
        }
    }
    @objc func applyMLBottleneck(_ thisURL: String, field: String, resolve: RCTPromiseResolveBlock, reject: RCTPromiseRejectBlock) {
        applyML(thisURL, field: field, resolve: resolve, reject: reject) { request, error in
            guard error == nil, let results = request.results else { return }
            if let m = self.ms[thisURL], let models = self.br[field]?[thisURL] {
                //build bottlenecks for each of them
                let input = MLDictionaryFeatureProvider();
                if m.modelDescription.outputDescriptionsByName.count == 0 {
                    if(results.count == 1 ) {
                        let label = m.modelDescription.predictedFeatureName ?? "bottleneck"
                        if let fvo = results.first as? VNCoreMLFeatureValueObservation {
                            input.setValue(fvo.featureValue, forKey: label)
                        }
                    } else {
                        //Boned we are
                    }
                } else {
                    //@TODO this is a flier to see if we can walk the descriptions to get this, boyo
                    let names = Array(m.modelDescription.outputDescriptionsByName.keys)
                    for i in 1...results.count {
                        let result = results[i]
                        guard let fvo = result as? VNCoreMLFeatureValueObservation else { continue }
                        input.setValue(fvo.featureValue, forKey: names[i])
                    }
                }
                if input.featureNames.count > 0 {
                    for (_, info) in models {
                        guard let out = try? info.model.prediction(from: input) else { continue }
                        info.callback(out, info.model)
                    }
                }
            }
        }
    }
    @objc func applyMLGeneric(_ thisURL: String, field: String, resolve: RCTPromiseResolveBlock, reject: RCTPromiseRejectBlock) {
        applyML(thisURL, field: field, resolve: resolve, reject: reject) { request, error in
            guard error == nil, let results = request.results else { return }
            if let m = self.ms[thisURL] {
                var input:[String: Any] = [:]
                if m.modelDescription.outputDescriptionsByName.count == 0 {
                    if(results.count == 1 ) {
                        let label = m.modelDescription.predictedFeatureName ?? "bottleneck"
                        if let fvo = results.first as? VNCoreMLFeatureValueObservation {
                            (_, input[label]) = convertFeatureValue(fvo.featureValue)
                        }
                    } else {
                        //Boned we are
                    }
                } else {
                    //@TODO this is a flier to see if we can walk the descriptions to get this, boyo
                    let names = Array(m.modelDescription.outputDescriptionsByName.keys)
                    for i in 1...results.count {
                        let result = results[i]
                        guard let fvo = result as? VNCoreMLFeatureValueObservation else { continue }
                        (_, input[names[i]]) = convertFeatureValue(fvo.featureValue)
                    }
                }
                if input.count > 0 {
                    self.sendEvent(withName: "RNVision", body: ["region": field, "key": thisURL, "data": input])
                }
            }
            
        }
    }
    @objc func removeML(_ thisURL: String, field: String, resolve: RCTPromiseResolveBlock, reject: RCTPromiseRejectBlock) {
        ir[field]?.removeValue(forKey: thisURL)
        if ir[field]?.keys.count == 0 {
            ir.removeValue(forKey: field)
        }
        resolve(true)
    }
    func applyBottleneck(_ thisURL: String, toField: String, toModel: String, resolve: RCTPromiseResolveBlock, reject: RCTPromiseRejectBlock, callback: @escaping BottleneckCB) {
        var origmodel:MLModel?
        if origmodel == nil {
            guard let modelURL = URL(string: thisURL) else { reject("bad_url", "This is a bad URL", nil); return  }
            guard let o = try? MLModel(contentsOf: modelURL) else { reject("no_model", "No model at " + thisURL, nil); return }
            ms[thisURL] = o
            origmodel = o
        }
        guard let o = origmodel else { reject("no_mode", "Could not make/find a model at " + thisURL, nil); return }
        let info = ModelStruct(model: o, callback: callback)
        if br[toField] == nil {
            br[toField] = [:]
        }
        if br[toField]![toModel] == nil {
            br[toField]![toModel] = [:]
        }
        br[toField]![toModel]![thisURL] = info
        resolve(thisURL)
    }
    @objc func applyBottleneckClassifier(_ thisURL: String, toField: String, toModel: String, maxResults: Int, resolve: RCTPromiseResolveBlock, reject: RCTPromiseRejectBlock) {
        applyBottleneck(thisURL, toField: toField, toModel: toModel, resolve: resolve, reject: reject) { fp, model in
            //Find the classifer
            for name in fp.featureNames {
                guard let fv = fp.featureValue(for: name), fv.type == .dictionary, let original = fp.featureValue(for: name)?.dictionaryValue else { continue }
                let dic = original.sorted() { a, b in
                    return Float(b.value) < Float(a.value) // Reversing the order - want highest values at the top
                }
                var out:[[String: Any]] = []
                for (key, value) in dic {
                    out.append(["label": key, "confidence": value])
                }
                self.sendEvent(withName: "RNVision", body: ["key": thisURL, "bottleneck": toModel, "data": out])
                break
            }
        }
    }
    @objc func applyBottleneckGenerator(_ thisURL: String, handler: String, toField: String, toModel: String, resolve: RCTPromiseResolveBlock, reject: RCTPromiseRejectBlock) {
        applyBottleneck(thisURL, toField: toField, toModel: toModel, resolve: resolve, reject: reject) { fp, model in
            for name in fp.featureNames {
                guard let fv = fp.featureValue(for: name), fv.type == .image, let i = fv.imageBufferValue else { continue }
                self.pixelBuffers[thisURL] = i
                if handler == "sendEvent" {
                    self.sendEvent(withName: "RNVision", body: ["key": thisURL])
                }
                break
            }
        }
    }
    @objc func applyBottleneckBottleneck(_ thisURL: String, toField: String, toModel: String, resolve: RCTPromiseResolveBlock, reject: RCTPromiseRejectBlock) {
        applyBottleneck(thisURL, toField: toField, toModel: toModel, resolve: resolve, reject: reject) { fp, model in
            guard let bottlenecks = self.br[toField]?[thisURL] else { return }
            for (_, ms) in bottlenecks {
                let m = ms.model
                let cb = ms.callback
                cb(fp, m)
            }
        }
    }
    @objc func applyBottleneckGeneric(_ thisURL: String, toField: String, toModel: String, resolve: RCTPromiseResolveBlock, reject: RCTPromiseRejectBlock) {
        applyBottleneck(thisURL, toField: toField, toModel: toModel, resolve: resolve, reject: reject) { fp, model in
            var out:[String: Any] = [:]
            for n in fp.featureNames {
                guard let fv = fp.featureValue(for: n) else { continue }
                (_, out[n]) = convertFeatureValue(fv)
            }
            if out.count > 0 {
                self.sendEvent(withName: "RNVML", body: ["key": thisURL, "bottleneck": toModel, "data": out])
            }
        }
    }
    @objc func removeBottleneck(_ modelURL:String, fromField: String, fromModel: String, resolve: RCTPromiseResolveBlock, reject: RCTPromiseRejectBlock) {
        guard let _ = br[fromField] else { reject("no_parent_field", "There is no parent field " + fromField, nil); return }
        guard let _ = br[fromField]![fromModel] else { reject("no_parent_model", "There is no parent model " + fromModel, nil); return }
        br[fromField]![fromModel]!.removeValue(forKey: modelURL)
        resolve(true)
    }
    @objc func removeBottlenecks(_ fromField:String, fromModel: String, resolve: RCTPromiseResolveBlock, reject: RCTPromiseRejectBlock) {
        guard let keys = br[fromField]?[fromModel]?.keys else { resolve(["removedBottlenecks": 0]); return }
        br[fromField]!.removeValue(forKey: fromModel)
        resolve(["removedBottlenecks": keys])
    }
    //MARK: Region Management
    @objc func setRegion(_ region: String, rectDic: [String: Any], resolve: RCTPromiseResolveBlock, reject: RCTPromiseRejectBlock) {
        regions[region] = dictionaryToRect(rectDic);
        resolve(region)
    }
    @objc func removeRegion(_ region: String, resolve: RCTPromiseResolveBlock, reject: RCTPromiseRejectBlock) {
        regions.removeValue(forKey: region)
        resolve(true) 
    }
    //MARK: MultiArray access
    @objc func saveMultiArray(key: String, resolve: RCTPromiseResolveBlock, reject: RCTPromiseRejectBlock) {
        guard let m = multiArrays[key] else { reject("no_multiarray", "No Multiarrays with key " + key, nil); return }
        let url = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(key).appendingPathExtension(makeMultiArrayExtension(multiArray: m))
        if RHDVision.saveMultiArray(multiArray: m, url: url) {
            resolve(url.absoluteString)
        } else { resolve(false) }
    }
    //MARK: Metadata Capture
    func captureOutput(_ output: AVCaptureOutput!, didOutputMetadataObjects metadataObjects: [Any]!, from connection: AVCaptureConnection!) {
        metadataObjects.forEach() {obj in
            if let ro = obj as? AVMetadataMachineReadableCodeObject {
                guard let sv = ro.stringValue else {return}
                self.foundMetaData(sv)
            }
        }
    }
    func foundMetaData(_ stringValue:String) {
        sendEvent(withName: "RNVMetaData", body:["string": stringValue])
    }
    //MARK: RCTEventEmitter Support
    override func supportedEvents() -> [String]! {
        return ["RNVision", "RNVMetaData"]
    }
    //MARK: Potential dumping
    func AVRectToPL(_ avRect: CGRect) -> CGRect {
        let mr = getMetaRectangle()
        let innerRect = convertOuterToInner(
            outerRect: avRect ,
            innerRect: mr
        )
        let mirroredRect = fixMirroredRect(innerRect, isMirrored: self.cachedVideoMirrored)
        return mirroredRect
    }
    func PLRectToAV(_ plRect: CGRect) -> CGRect {
        let mr = getMetaRectangle()
        let or = convertInnerToOuter(innerRect: plRect, outerRect: mr)
        let mir = fixMirroredRect(or, isMirrored: self.cachedVideoMirrored)
        return mir
    }
    func fixMirroredRect(_ sourceRect: CGRect) -> CGRect {
        return fixMirroredRect(sourceRect, isMirrored: true)
    }
    func fixMirroredRect(_ sourceRect:CGRect, isMirrored: Bool) -> CGRect {
        return CGRect(
            x: isMirrored ? 1.0 - sourceRect.origin.x - sourceRect.size.width : sourceRect.origin.x,
            y: sourceRect.origin.y,
            width: sourceRect.size.width,
            height: sourceRect.size.height
        )
    }
    func turnRect(_ oRect: CGRect, degrees: Int) -> CGRect{
        var degrees = degrees
        while degrees < 0 { degrees = degrees + 360 }
        while degrees > 360 { degrees = degrees - 360 }
        print("I am turning degrees!", degrees)
        switch(degrees) {
        case 90:
            //Turning from portrait to landscaperight
            return CGRect(
                x: 1.0 - oRect.origin.y - oRect.size.height,
                y: oRect.origin.x,
                width: oRect.size.height,
                height: oRect.size.width)
        case 180:
            //Turning all the way over, obvs!
            return CGRect(
                x: 1.0 - oRect.origin.x - oRect.size.width,
                y: 1.0 - oRect.origin.y - oRect.size.height,
                width: oRect.size.width,
                height: oRect.size.height)
        case 270:
            //Turning from landscaperight to portrait
            return CGRect(
                x: oRect.origin.y,
                y: 1.0 - oRect.origin.x - oRect.size.width,
                width: oRect.size.height,
                height: oRect.size.width)
        default:
            //No rotation:
            return oRect
        }
    }
    func orientationChangeToDegrees(startOrientation: AVCaptureVideoOrientation, endOrientation: AVCaptureVideoOrientation) -> Int {
        
        let endDegrees = orientationToDegrees(endOrientation)
        let startDegrees = orientationToDegrees(startOrientation)
        print("turning from ", endDegrees, startDegrees)
        let difference =  endDegrees - startDegrees
        print("Difference is ", difference)
        return difference
    }
    func orientationToDegrees(_ orientation: AVCaptureVideoOrientation) -> Int {
        switch orientation {
        case AVCaptureVideoOrientation.portrait:
            return 0
        case AVCaptureVideoOrientation.portraitUpsideDown:
            return 180
        case AVCaptureVideoOrientation.landscapeLeft:
            return 270
        case AVCaptureVideoOrientation.landscapeRight:
            return 90
        }
    }
    func orientedRectToOriginal(_ oRect: CGRect) -> CGRect {
        let _ = getMetaRectangle()
        return turnRect(oRect, degrees: orientationChangeToDegrees(startOrientation: cachedAVOrientation, endOrientation: AVCaptureVideoOrientation.landscapeRight))
    }
    func originalRectToOriented(_ oRect: CGRect) -> CGRect {
        let _ = getMetaRectangle()
        return turnRect(oRect, degrees: orientationChangeToDegrees(startOrientation: AVCaptureVideoOrientation.landscapeRight, endOrientation: cachedAVOrientation))
    }
    var cachedMetaRectangle:CGRect = CGRect(x:0, y:0, width: 0, height: 0)
    var cachedOriginalMetaRectangle:CGRect = CGRect(x:0, y:0, width: 0, height: 0)
    var cachedAVOrientation:AVCaptureVideoOrientation = AVCaptureVideoOrientation.portrait
    var cachedVideoMirrored:Bool = false
    func getMetaRectangle() -> CGRect {
        guard cachedOriginalMetaRectangle.size.height > 0 else {
            return loadMetaRectangleInfo()
        }
        return cachedMetaRectangle
    }
    func loadMetaRectangleInfo() -> CGRect {
        guard let pl = pl else { return cachedMetaRectangle }
        let mr = pl.metadataOutputRectOfInterest(for: pl.visibleRect)
        cachedVideoMirrored =  pl.connection.isVideoMirrored
        cachedOriginalMetaRectangle = mr;
        cachedAVOrientation = pl.connection.videoOrientation
        cachedMetaRectangle = turnRect(mr, degrees: orientationChangeToDegrees(startOrientation: AVCaptureVideoOrientation.landscapeRight, endOrientation: cachedAVOrientation))
        return cachedMetaRectangle
    }
    
}
//MARK: Orientation Conversion
func deviceOrientationtoAVOrientation(_ uiorientation:UIDeviceOrientation) -> AVCaptureVideoOrientation {
    switch uiorientation {
    case .landscapeLeft:
        return .landscapeRight //Note left and right get flipped
    case .landscapeRight:
        return .landscapeLeft //Note Left and Right get flipped
    case .portrait:
        return .portrait
    case .portraitUpsideDown:
        return .portraitUpsideDown
    case .unknown:
        return .portrait
    default:
        return .portrait
    }
}
func AVOrientationToDeviceOrientation(_ avorientation:AVCaptureVideoOrientation) -> UIDeviceOrientation {
    switch avorientation {
    case .landscapeLeft: return .landscapeLeft
    case .landscapeRight: return .landscapeRight
    case .portrait: return .portrait
    case .portraitUpsideDown: return .portraitUpsideDown
    }
    
}
//MARK: Relative Rectangle Conversion
func convertInnerToOuter(innerRect: CGRect, outerRect: CGRect) -> CGRect{
    //Assuming all 0-1 coordinates, where innerRect is relative to outerRect, and outerRect is relative to target rect space
    return CGRect(
        x: innerRect.origin.x * outerRect.size.width + outerRect.origin.x,
        y: innerRect.origin.y * outerRect.size.height + outerRect.origin.y,
        width: innerRect.size.width * outerRect.size.width,
        height: innerRect.size.height * outerRect.size.height
    )
}
func convertOuterToInner(outerRect: CGRect, innerRect: CGRect) -> CGRect {
    //Given a rectangle in coordinates relative to outer (outerRect) Returns coordinates relative to innerRect
    return CGRect(
        x: (outerRect.origin.x - innerRect.origin.x) / innerRect.size.width,
        y: (outerRect.origin.y - innerRect.origin.y) / innerRect.size.height,
        width: outerRect.size.width / innerRect.size.width,
        height: outerRect.size.height / innerRect.size.height
    )
}
//MARK: Feature Management and MultiArrays
var multiArrays:[String:MLMultiArray] = [:]
func convertFeatureValue(_ v:MLFeatureValue) -> (String, Any?) {
    let t:MLFeatureType = v.type
    var o:Any?;
    var ts:String = "";
    switch t {
    case MLFeatureType.string:
        ts = "string";
        o = v.stringValue;
    case MLFeatureType.double:
        ts = "double";
        o = v.doubleValue;
    case MLFeatureType.int64:
        ts = "int64";
        o = v.int64Value;
    case MLFeatureType.dictionary:
        ts = "dictionary";
        o = v.dictionaryValue
    case MLFeatureType.image:
        if let cvib:CVImageBuffer = v.imageBufferValue {
            let tempURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(UUID().uuidString).appendingPathExtension("jpg")
            let ci = CIImage(cvImageBuffer: cvib)
            let ui = UIImage(ciImage: ci)
            if let _ = try? UIImageJPEGRepresentation(ui, 1.0)?.write(to: tempURL) {
                o = tempURL.absoluteString
            } else { o = "COULDNOTWRITE" }
            ts = "image";
        }
    case MLFeatureType.invalid:
        print("This was an invalid answer");
    case MLFeatureType.multiArray:
        if let m = v.multiArrayValue {
            ts = "multiarray"
            let k = UUID().uuidString
            multiArrays[k] = m
            o = k
        }
    }
    return (ts, o)
}
func saveMultiArray(multiArray: MLMultiArray, path:String) -> Bool {
    let url = URL(fileURLWithPath: path)
    return saveMultiArray(multiArray: multiArray, url: url);
}
func saveMultiArray(multiArray: MLMultiArray, url: URL) -> Bool {
    var size:Int = 1;
    var unitSize:Int
    switch multiArray.dataType {
    case .double: unitSize = 8;
    case .float32: unitSize = 4;
    case .int32: unitSize = 4;
    }
    for  dim in 1...multiArray.shape.count {
        size = size * (multiArray.shape[dim] as! Int) * (multiArray.strides[dim] as! Int) * unitSize
    }
    let d = NSData(bytes: multiArray.dataPointer, length: size)
    do {
        try d.write(to: url, options: .atomic)
        return true
    } catch  {
        return false
    }
}
func makeMultiArrayExtension(multiArray: MLMultiArray) -> String {
    var t:String
    switch multiArray.dataType {
    case .double: t = "double";
    case .float32: t = "float32";
    case .int32: t = "int32";
    }
    for n in multiArray.shape {
        t = t.appending(".").appending(n.stringValue)
    }
    t = t.appending(".").appending("s")
    for n in multiArray.strides {
        t = t.appending(".").appending(n.stringValue)
    }
    return t
}
//MARK: Editing PixelBuffers
public func resizePixelBuffer(_ srcPixelBuffer: CVPixelBuffer,
                              cropX: Int,
                              cropY: Int,
                              cropWidth: Int,
                              cropHeight: Int,
                              scaleWidth: Int,
                              scaleHeight: Int) -> CVPixelBuffer? {
    CVPixelBufferLockBaseAddress(srcPixelBuffer, CVPixelBufferLockFlags(rawValue: 0))
    guard let srcData = CVPixelBufferGetBaseAddress(srcPixelBuffer) else {
        print("Error: could not get pixel buffer base address")
        return nil
    }
    let srcBytesPerRow = CVPixelBufferGetBytesPerRow(srcPixelBuffer)
    let offset = cropY*srcBytesPerRow + cropX*4
    var srcBuffer = vImage_Buffer(data: srcData.advanced(by: offset),
                                  height: vImagePixelCount(cropHeight),
                                  width: vImagePixelCount(cropWidth),
                                  rowBytes: srcBytesPerRow)
    let destBytesPerRow = scaleWidth*4
    guard let destData = malloc(scaleHeight*destBytesPerRow) else {
        print("Error: out of memory")
        return nil
    }
    var destBuffer = vImage_Buffer(data: destData,
                                   height: vImagePixelCount(scaleHeight),
                                   width: vImagePixelCount(scaleWidth),
                                   rowBytes: destBytesPerRow)
    let error = vImageScale_ARGB8888(&srcBuffer, &destBuffer, nil, vImage_Flags(0))
    CVPixelBufferUnlockBaseAddress(srcPixelBuffer, CVPixelBufferLockFlags(rawValue: 0))
    if error != kvImageNoError {
        print("Error:", error)
        free(destData)
        return nil
    }
    let releaseCallback: CVPixelBufferReleaseBytesCallback = { _, ptr in
        if let ptr = ptr {
            free(UnsafeMutableRawPointer(mutating: ptr))
        }
    }
    let pixelFormat = CVPixelBufferGetPixelFormatType(srcPixelBuffer)
    var dstPixelBuffer: CVPixelBuffer?
    let status = CVPixelBufferCreateWithBytes(nil, scaleWidth, scaleHeight,
                                              pixelFormat, destData,
                                              destBytesPerRow, releaseCallback,
                                              nil, nil, &dstPixelBuffer)
    if status != kCVReturnSuccess {
        print("Error: could not create new pixel buffer")
        free(destData)
        return nil
    }
    return dstPixelBuffer
}
func slicePixelBuffer(_ cvp: CVPixelBuffer, toRect: CGRect) -> CVPixelBuffer? {
    //Rect time! let's get the rectangle we represent from the buffer
    let sourceHeight:Int = CVPixelBufferGetHeight(cvp)
    let sourceWidth:Int = CVPixelBufferGetWidth(cvp)
    let cropWidth = Int(toRect.width * CGFloat(sourceWidth))
    let cropHeight = Int(toRect.height * CGFloat(sourceHeight))
    let cropX = Int(toRect.origin.x * CGFloat(sourceWidth))
    let cropY = Int(toRect.origin.y * CGFloat(sourceHeight))
    return resizePixelBuffer(cvp, cropX: cropX, cropY: cropY, cropWidth: cropWidth, cropHeight: cropHeight, scaleWidth: sourceWidth, scaleHeight: sourceHeight)
}
//MARK: Rectangle Conversion
func visionRectToNormal(_ visionRect: CGRect)->CGRect {
    var newRect = visionRect
    newRect.origin.y = 1 - visionRect.origin.y - visionRect.size.height
    return newRect
}
func normalRectToVision(_ normalRect: CGRect) -> CGRect {
    return CGRect(
        x: normalRect.origin.x,
        y: 1 - (normalRect.origin.y + normalRect.size.height),
        width: normalRect.size.width,
        height: normalRect.size.height
    )
}
func  rectToDictionary(_ rect:CGRect) -> [String: Any] {
    return [
        "x": rect.origin.x,
        "y": rect.origin.y,
        "height": rect.size.height,
        "width": rect.size.width]
}
func dictionaryToRect(_ dic:[String: Any]) -> CGRect? {
    guard
        let x = dic["x"] as? CGFloat,
        let y = dic["y"] as? CGFloat,
        let height = dic["height"] as? CGFloat,
        let width = dic["width"] as? CGFloat
        else { return nil }
    return CGRect(x: x, y: y, width: width,height: height)
}
