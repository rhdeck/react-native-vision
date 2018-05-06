import AVKit
@objc(RHDVisionViewManager)
class RHDVisionViewManager: RCTViewManager {
    static var currentView: RHDVisionView?
    override func view() -> UIView {
        if let v = RHDVisionViewManager.currentView {
            v.cancel()
            RHDVisionViewManager.currentView = nil
        }
        let v = RHDVisionView()
        RHDVisionViewManager.currentView = v
        v.manager = self
        return v
    }
    override class func requiresMainQueueSetup() -> Bool {
        return false
    }
    
   
    func closedView(_ v:RHDVisionView) {}
}
