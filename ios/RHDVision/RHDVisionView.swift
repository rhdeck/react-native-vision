import UIKit
import AVKit
@objc(RHDVisionCameraView)
class RHDVisionCameraView: UIView {
    var pl:AVCaptureVideoPreviewLayer?
    var manager: RHDVisionCameraViewManager?
    var gravity:String = AVLayerVideoGravityResizeAspectFill
    func attach(_ session:AVCaptureSession) {
        attach(session, gravity: self.gravity)
    }
    func attach(_ session: AVCaptureSession, gravity: String) {
        self.gravity = gravity
        guard let pl = AVCaptureVideoPreviewLayer(session: session)  else { return }
        DispatchQueue.main.async(){
            pl.frame = self.bounds
            pl.videoGravity = gravity
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
