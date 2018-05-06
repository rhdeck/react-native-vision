#import <React/RCTViewManager.h>
#import <React/RCTEventEmitter.h>
#import <React/RCTBridgeModule.h>
@interface RCT_EXTERN_MODULE(RHDVisionModule, RCTEventEmitter)
RCT_EXTERN_METHOD(saveFrame:(NSString *)disposition resolve:(RCTPromiseResolveBlock)resolve reject:(RCTPromiseRejectBlock)reject);
RCT_EXTERN_METHOD(detectFaces:(RCTPromiseResolveBlock)resolve reject:(RCTPromiseRejectBlock)reject);
RCT_EXTERN_METHOD(trackObject:(NSString *)name dict:(NSDictionary *)dict resolve:(RCTPromiseResolveBlock)resolve reject:(RCTPromiseRejectBlock)reject);
RCT_EXTERN_METHOD(applyML:(NSString *)thisURL resolve:(RCTPromiseResolveBlock)resolve reject:(RCTPromiseRejectBlock)reject);
RCT_EXTERN_METHOD(attach);
@end
@interface RCT_EXTERN_MODULE(RHDVisionViewManager, RCTViewManager)
RCT_EXPORT_VIEW_PROPERTY(onStart, RCTBubblingEventBlock);
RCT_EXPORT_VIEW_PROPERTY(cameraFront, BOOL);
@end