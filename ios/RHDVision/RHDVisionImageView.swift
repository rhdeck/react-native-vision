import Foundation
@objc(RHDVisionImageView)
class RHDVisionImageView: UIView {
    var _id:String = ""
    var imageView = UIImageView()
    var manager:RHDVisionImageViewManager?
    var isAdded = false
    @objc var isMirrored:Bool = false
    @objc var resizeMode:String  {
        get { return "fuck you" }
        set(c) { imageView.contentMode = resizeModeToContentMode(c)
            if(!isAdded) {
                addSubview(imageView);
                isAdded = true
            }
        }
    }
    var image:UIImage? {
        get {return imageView.image}
        set(i) { imageView.image = isMirrored ? i?.withHorizontallyFlippedOrientation() : i }
    }
    @objc var id: String {
        get { return _id }
        set(newID) {
            if let m = manager {
                _id = newID
                m.views[_id] = self
            }
        }
    }
    override func layoutSubviews() {
        super.layoutSubviews()
        imageView.frame = bounds
    }
}
func resizeModeToContentMode(_ resizeMode: String) -> UIViewContentMode {
    switch resizeMode {
    case "cover": return UIViewContentMode.scaleAspectFill
    case "stretch": return UIViewContentMode.scaleToFill
    case "contain": return UIViewContentMode.scaleAspectFit
    case "center": return UIViewContentMode.center
    case "repeat": return UIViewContentMode.redraw
    default: return UIViewContentMode.scaleAspectFill
    }
}
func contentModeToResizeMode(_ contentMode: UIViewContentMode) -> String {
    switch(contentMode) {
    case .scaleAspectFill: return "cover"
    case .scaleToFill: return "stretch"
    case .scaleAspectFit: return "contain"
    case .center: return "center"
    case .redraw: return "redraw"
    default: return ""
    }
}
