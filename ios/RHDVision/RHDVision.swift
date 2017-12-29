import AVKit
@objc(RHDVision)
class RHDVisionManager: RCTViewManager {
    static var currentView: RHDVisionView?
    override func view() -> UIView {
        if let v = RHDVisionManager.currentView {
            v.cancel()
            RHDVisionManager.currentView = nil
        }
        let v = RHDVisionView()
        RHDVisionManager.currentView = v
        v.manager = self
        return v
    }
    override class func requiresMainQueueSetup() -> Bool {
        return false
    }
    
   
    func closedView(_ v:RHDVisionView) {}
}
