import AVKit
import Vision
import Photos
import Foundation

typealias SFCallback = (UIImage)->Void
typealias VNRGenerator = ()->VNRequest?
// Don't know if I want this typealias VNReqMaker = () -> VNRequest
@objc(RHDVisionModule)
class RHDVisionDelegate: RCTEventEmitter, AVCaptureVideoDataOutputSampleBufferDelegate, AVCaptureMetadataOutputObjectsDelegate {
    var sr:[String:VNRequest] = [:]
    var srobs:[String:VNDetectedObjectObservation] = [:]
    var ir:[String:VNRequest] = [:]
    var srg:[String:VNRGenerator] = [:]
    var irg:[String:VNRGenerator] = [:]
    var sf: [String: SFCallback] = [:]
    var pl:AVCaptureVideoPreviewLayer?
    var connection: AVCaptureConnection?
    var srh = VNSequenceRequestHandler()
    func resetSRH() {
        srh = VNSequenceRequestHandler()
    }
    func captureOutput(_ output: AVCaptureOutput!, didOutputSampleBuffer sampleBuffer: CMSampleBuffer!, from connection: AVCaptureConnection!) {
        self.connection = connection
        guard sr.count > 0
            || srg.count > 0
            || ir.count > 0
            || irg.count > 0
            || sf.count > 0,
            let cvp = CMSampleBufferGetImageBuffer(sampleBuffer)
        else { return }
        var irs:[VNRequest] = []
        if ir.count > 0 {
            irs = Array(ir.values)
        }
        irg.values.forEach() { generator in
            if let r = generator() { irs.append(r) }
        }
        if irs.count > 0 {
            let irh = VNImageRequestHandler(cvPixelBuffer: cvp, options: [:])
            try? irh.perform(irs)
        }
        var srs:[VNRequest] = []
        if sr.count > 0  {
            srs = Array(sr.values)
        }
        srg.values.forEach() { generator in
            if let r = generator() { srs.append(r) }
        }
        if srs.count > 0 {
            
            try? srh.perform(srs, on: cvp)
        }
        if sf.count > 0 {
            let ci = CIImage(cvPixelBuffer: cvp)
            let context = CIContext(options: nil)
            let mr = getMetaRectangle()
            let height = CVPixelBufferGetHeight(cvp)
            let width = CVPixelBufferGetWidth(cvp)
            let size = CGSize(width: width, height: height)
            let newRect = CGRect(
                x: mr.origin.x * size.width,
                y: mr.origin.y * size.height,
                width: mr.size.width * size.width,
                height: mr.size.height * size.height)
            if let cgi = context.createCGImage(ci, from:newRect) {
                let i = UIImage(cgImage:cgi)
                sf.values.forEach(){ cb in
                    cb(i)
                }
            }
        }
    }
    func addSaveFrameHandler(handler: @escaping SFCallback) -> String {
        return addSaveFrameHandler(label: nil, handler: handler)
    }
    func addSaveFrameHandler( label: String?, handler: @escaping SFCallback) -> String{
        let l = label ?? UUID().uuidString
        sf[l] = handler;
        return l
    }
    func removeSaveFrameHandler(label: String) {
        sf.removeValue(forKey: label)
    }
    func getSaveFrameHandler(label: String) -> SFCallback? {
        return sf[label]
    }
    
    let defaultDisposition:String = "file"
    var savedFrame:UIImage?
    @objc func saveFrame(_ disposition: String?, resolve: @escaping RCTPromiseResolveBlock, reject: @escaping RCTPromiseRejectBlock) {
        guard getSaveFrameHandler(label: "saveFrame") == nil else { reject("Already Saving a frame", nil, nil); return }
        let _ =  addSaveFrameHandler(label: "saveFrame") { i in
            self.removeSaveFrameHandler(label: "saveFrame")
            let d = disposition ?? self.defaultDisposition
            switch(d) {
            case "file":
                guard let d = UIImageJPEGRepresentation(i, 1.0) else { reject("Could not get data from frame", nil, nil); return }
                let u = UUID().uuidString
                let t = URL.init(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(u)
                do {
                    try d.write(to: t)
                    resolve(["status": "success", "url": t.absoluteString])
                    return
                } catch {
                    reject("Failed to save to temp file " + t.absoluteString, nil, error)
                    return
                }
            case "roll":
                switch PHPhotoLibrary.authorizationStatus() {
                case PHAuthorizationStatus.notDetermined:
                    PHPhotoLibrary.requestAuthorization(){ success in
                        switch PHPhotoLibrary.authorizationStatus() {
                        case PHAuthorizationStatus.denied:
                            reject("No permission to save to camera roll", nil, nil)
                        default:
                            UIImageWriteToSavedPhotosAlbum(i, nil, nil, nil)
                            resolve(["status": "success", "location": "photoroll"])
                        }
                    }
                case PHAuthorizationStatus.denied:
                    reject("No permission to save to camera roll", nil, nil)
                default:
                    UIImageWriteToSavedPhotosAlbum(i, nil, nil, nil)
                    resolve(["status": "success", "location": "photoroll"])
                }
            case "memory":
                self.savedFrame = i
                resolve(["status": "success", "location": "memory"])
            default:
                reject("Invalid disposition '" + d + "' provided", nil, nil)
            }
        }
    }
    @objc func detectFaces(_ resolve:@escaping RCTPromiseResolveBlock, reject:@escaping RCTPromiseRejectBlock) {
        guard ir["detectFaces"] == nil else { reject("Already running detect faces", nil,nil); return}
        ir["detectFaces"] = VNDetectFaceRectanglesRequest() { request, error in
            self.ir.removeValue(forKey: "detectFaces")
            var data:[Any] = []
            guard error == nil else { reject("Detection returned error", nil, error); return}
            guard let r = request.results else { resolve(data); return}
            r.forEach() { result in
                guard let rs = result as? VNDetectedObjectObservation else {return}
                let bb = rs.boundingBox
                let normalRect = self.visionRectToNormal(bb)
                let PLRect = self.AVRectToPL(normalRect)
                let convertedBB = PLRect
                data.append(self.rectToDictionary(convertedBB))
            }
            resolve(data)
        }
    }
    @objc func trackObject(_ name: String, dict: [String: Any], resolve: RCTPromiseResolveBlock, reject: RCTPromiseRejectBlock) {
        if let r = dictionaryToRect(dict) {
            if(trackObject(name, rect: r)) {
                resolve(nil)
            } else {
                reject(nil, nil, nil)
            }
        } else {
            reject(nil, nil, nil)
        }
    }
    func trackObject(_ name: String, rect: CGRect) -> Bool {
        let avrect = PLRectToAV(rect)
        let visionRect = normalRectToVision(avrect)
        let obs = VNDetectedObjectObservation(boundingBox: visionRect)
        srobs[name] = obs
        let rg:VNRGenerator = {
            guard let o = self.srobs[name] else { return nil }
            let r =  VNTrackObjectRequest(detectedObjectObservation: o) { request, error in
                DispatchQueue.main.async() {
                    guard
                        error == nil,
                        let newobs = request.results?.first as? VNDetectedObjectObservation
                    else { return }
                    let normalRect = self.visionRectToNormal(newobs.boundingBox)
                    let newBox = self.AVRectToPL(normalRect)
                    let oldobsQ = self.srobs[name]
                    self.srobs[name] = newobs
                    guard let oldobs = oldobsQ else { return }
                    guard newobs.boundingBox != oldobs.boundingBox else { return }
                    self.sendEvent(withName: "trackedObject", body: ["id": name, "frame": self.rectToDictionary(newBox), "confidence": newobs.confidence])
                }
            }
            r.preferBackgroundProcessing = true
            r.trackingLevel = .accurate
            return r
        }
        srg[name] = rg
        return true
    }
    @objc func applyML(_ thisURL: String, resolve:RCTPromiseResolveBlock, reject:RCTPromiseRejectBlock) {
        guard let modelURL = URL(string: thisURL) else { return }
        do {
            let origmodel = try MLModel(contentsOf: modelURL)
            let vnmodel = try VNCoreMLModel(for: origmodel)
            let r = VNCoreMLRequest(model: vnmodel ) { (request, error) in
                guard error == nil else { return }
                
            }
            ir[thisURL] = r;
            resolve(nil);
        } catch {
            reject(nil, nil, error)
        }
    }
    func captureOutput(_ output: AVCaptureOutput!, didOutputMetadataObjects metadataObjects: [Any]!, from connection: AVCaptureConnection!) {
        metadataObjects.forEach() {obj in
            if let ro = obj as? AVMetadataMachineReadableCodeObject {
                guard let sv = ro.stringValue else {return}
                self.foundMetaData(sv)
            }
        }
    }
    func foundMetaData(_ stringValue:String) {
        sendEvent(withName: "foundMetaData", body:["string": "stringValue"])
    }
    override func supportedEvents() -> [String]! {
        return [
            "foundMetaData",
            "trackedObject"
        ]
    }
    @objc func attach() {
        if let pl = RHDVisionManager.currentView?.pl {
            attachPL(previewLayer: pl)
        }
    }
    func attachPL(previewLayer: AVCaptureVideoPreviewLayer) {
        self.pl = previewLayer;
        self.start()
    }
    func start() {
        guard
            let pl = self.pl,
            let s = pl.session
        else {return}
        cachedMetaRectangle = CGRect(x:0, y:0, width: 0, height: 0)
        let o = AVCaptureVideoDataOutput()
        o.setSampleBufferDelegate(self, queue: DispatchQueue(label:"RHDVisionDelegateQueue"))
        o.alwaysDiscardsLateVideoFrames = true
        o.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA]
        s.addOutput(o)
        if let conn = o.connection(withMediaType: AVMediaTypeVideo) {
            conn.videoOrientation = deviceOrientationtoAVOrientation(UIDevice.current.orientation)
        }
    }
    func deviceOrientationtoAVOrientation(_ uiorientation:UIDeviceOrientation) -> AVCaptureVideoOrientation {
        switch uiorientation {
            case .landscapeLeft: return .landscapeLeft
            case .landscapeRight: return .landscapeRight
            case .portrait: return .portrait
            case .portraitUpsideDown:  return .portraitUpsideDown
            default: return .portrait
        }
    }
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
            //Flipping over, obs!
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
    func  rectToDictionary(_ rect:CGRect) -> [String: Any] {
        return [
            "x": rect.origin.x,
            "y": rect.origin.y,
            "height": rect.size.height,
            "width": rect.size.width]
    }
    func dictionaryToRect(_ dic:[String: Any]) -> CGRect? {
        guard
            let x = dic["x"] as? Float,
            let y = dic["y"] as? Float,
            let height = dic["height"] as? Float,
            let width = dic["width"] as? Float
        else { return nil }
        return CGRect(x: CGFloat(x), y: CGFloat(y), width: CGFloat(width),height: CGFloat(height))
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
    
}
