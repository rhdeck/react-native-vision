import Foundation
@objc(RHDVisionImageViewManager)
class RHDVisionImageViewManager: RCTViewManager {
    static var instance:RHDVisionImageViewManager?
    var views:[String: RHDVisionImageView] = [:]
    override init() {
        super.init()
        RHDVisionImageViewManager.instance = self
    }
    override func view() -> UIView! {
        let i = RHDVisionImageView()
        i.manager = self
        return i
    }
}
