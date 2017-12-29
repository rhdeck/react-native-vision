#import <React/RCTViewManager.h>
#import <React/RCTBridgeModule.h>

@interface RCT_EXTERN_MODULE(RHDVision, RCTViewManager)
RCT_EXPORT_VIEW_PROPERTY(cameraFront, BOOL)
RCT_EXPORT_VIEW_PROPERTY(onStart, RCTBubblingEventBlock)
@end
