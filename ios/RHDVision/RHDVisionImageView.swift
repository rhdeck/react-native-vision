import Foundation
@objc(RHDVisionImageView)
class RHDVisionImageView: UIImageView {
    var _id:String = ""
    var manager:RHDVisionImageViewManager?
    @objc var id: String {
        get { return _id }
        set(newID) {
            if let m = manager {
                _id = newID
                m.views[_id] = self
            }
        }
    }
}
