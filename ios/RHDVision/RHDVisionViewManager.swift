import AVKit
@objc(RHDVisionCameraViewManager)
class RHDVisionCameraViewManager: RCTViewManager {
    static var currentView: RHDVisionCameraView?
    override func view() -> UIView {
        if let v = RHDVisionCameraViewManager.currentView {
            v.detach()
            RHDVisionCameraViewManager.currentView = nil
        }
        let v = RHDVisionCameraView()
        RHDVisionCameraViewManager.currentView = v
        v.manager = self
        return v
    }
    override class func requiresMainQueueSetup() -> Bool {
        return false
    }
    func closedView(_ v:RHDVisionCameraView) {}
}
