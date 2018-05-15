import UIKit
import AVKit
@objc(RHDVisionCameraView)
class RHDVisionCameraView: UIView {
    var pl:AVCaptureVideoPreviewLayer?
    var manager: RHDVisionCameraViewManager?
    var _gravity:String = AVLayerVideoGravityResizeAspectFill
    @objc var gravity:String {
        get {return _gravity == AVLayerVideoGravityResizeAspectFill ? "fill" : "resize"
        }
        set(newGravity) {
            _gravity = newGravity == "fill" ? AVLayerVideoGravityResizeAspectFill : AVLayerVideoGravityResizeAspect
            if let p = pl {
                p.videoGravity = _gravity
            }
        }
    }
    func attach(_ session: AVCaptureSession) {
        DispatchQueue.main.async(){
            guard let pl = AVCaptureVideoPreviewLayer(session: session)  else { return }
            pl.frame = self.bounds
            pl.videoGravity = self._gravity
            self.layer.addSublayer(pl)
            self.pl = pl
        }
    }
    func detach() {
        if let pl = self.pl {
            pl.removeFromSuperlayer();
        }
        pl = nil
        if let manager = self.manager {
            manager.closedView(self)
        }
    }
    override func layoutSubviews() {
        super.layoutSubviews()
        if let c = pl?.connection {
            if c.isVideoOrientationSupported {
                c.videoOrientation = deviceOrientationtoAVOrientation(UIDevice.current.orientation)
            }
        }
        pl?.frame = self.bounds
    }
}
