#import <React/RCTViewManager.h>
#import <React/RCTEventEmitter.h>
#import <React/RCTBridgeModule.h>
@interface RCT_EXTERN_MODULE(RHDVisionModule, RCTEventEmitter)
RCT_EXTERN_METHOD(start:(BOOL)cameraFront resolve:(RCTPromiseResolveBlock)resolve reject:(RCTPromiseRejectBlock)reject);
RCT_EXTERN_METHOD(stop:(RCTPromiseResolveBlock)resolve reject:(RCTPromiseRejectBlock)reject);
RCT_EXTERN_METHOD(getImageDimensions:(RCTPromiseResolveBlock)resolve reject:(RCTPromiseRejectBlock)reject);
RCT_EXTERN_METHOD(attachCameraView:(RCTPromiseResolveBlock)resolve reject:(RCTPromiseRejectBlock)reject);
RCT_EXTERN_METHOD(detachCameraView:(RCTPromiseResolveBlock)resolve reject:(RCTPromiseRejectBlock)reject);
RCT_EXTERN_METHOD(cameraIsView:(BOOL)newIsCameraView resolve:(RCTPromiseResolveBlock)resolve reject:(RCTPromiseRejectBlock)reject);
RCT_EXTERN_METHOD(saveFrame:(NSString *)disposition region:(NSString *)region resolve:(RCTPromiseResolveBlock)resolve reject:(RCTPromiseRejectBlock)reject);
RCT_EXTERN_METHOD(removeSaveFrame:(NSString *)region resolve:(RCTPromiseResolveBlock)resolve reject:(RCTPromiseRejectBlock)reject);
RCT_EXTERN_METHOD(detectFaces:(NSString *)region resolve:(RCTPromiseResolveBlock)resolve reject:(RCTPromiseRejectBlock)reject);
RCT_EXTERN_METHOD(removeDetectFaces:(NSString *)region resolve:(RCTPromiseResolveBlock)resolve reject:(RCTPromiseRejectBlock)reject);
RCT_EXTERN_METHOD(trackObject:(NSString *)name region:(NSString *)region dict:(NSDictionary *)dict resolve:(RCTPromiseResolveBlock)resolve reject:(RCTPromiseRejectBlock)reject);
RCT_EXTERN_METHOD(removeTrackObject:(NSString *)name region:(NSString *)region resolve:(RCTPromiseResolveBlock)resolve reject:(RCTPromiseRejectBlock)reject);
RCT_EXTERN_METHOD(removeTrackObjects:(NSString *)region resolve:(RCTPromiseResolveBlock)resolve reject:(RCTPromiseRejectBlock)reject);
RCT_EXTERN_METHOD(applyMLClassifier:(NSString *)thisURL field:(NSString *)field resultMax:(NSInteger)resultMax resolve:(RCTPromiseResolveBlock)resolve reject:(RCTPromiseRejectBlock)reject);
RCT_EXTERN_METHOD(applyMLGenerator:(NSString *)thisURL field:(NSString *)field handler:(NSString *)handler resolve:(RCTPromiseResolveBlock)resolve reject:(RCTPromiseRejectBlock)reject);
RCT_EXTERN_METHOD(applyMLBottleneck:(NSString *)thisURL field:(NSString *)field resolve:(RCTPromiseResolveBlock)resolve reject:(RCTPromiseRejectBlock)reject);
RCT_EXTERN_METHOD(applyMLGeneric:(NSString *)thisURL field:(NSString *)field resolve:(RCTPromiseResolveBlock)resolve reject:(RCTPromiseRejectBlock)reject);
RCT_EXTERN_METHOD(removeML:(NSString *)thisURL field:(NSString *)field resolve:(RCTPromiseResolveBlock)resolve reject:(RCTPromiseRejectBlock)reject);
RCT_EXTERN_METHOD(applyBottleneckClassifier:(NSString *)thisURL toField:(NSString *)toField toModel:(NSString *)toModel maxResults:(NSInteger)maxResults resolve:(RCTPromiseResolveBlock)resolve reject:(RCTPromiseRejectBlock)reject);
RCT_EXTERN_METHOD(applyBottleneckGenerator:(NSString *)thisURL handler:(NSString *)handler toField:(NSString *)toField toModel:(NSString *)toModel resolve:(RCTPromiseResolveBlock)resolve reject:(RCTPromiseRejectBlock)reject);
RCT_EXTERN_METHOD(applyBottleneckBottleneck:(NSString *)thisURL toField:(NSString *)toField toModel:(NSString *)toModel resolve:(RCTPromiseResolveBlock)resolve reject:(RCTPromiseRejectBlock)reject);
RCT_EXTERN_METHOD(applyBottleneckGeneric:(NSString *)thisURL toField:(NSString *)toField toModel:(NSString *)toModel resolve:(RCTPromiseResolveBlock)resolve reject:(RCTPromiseRejectBlock)reject);
RCT_EXTERN_METHOD(removeBottleneck:(NSString *)modelURL fromField:(NSString *)fromField fromModel:(NSString *)fromModel resolve:(RCTPromiseResolveBlock)resolve reject:(RCTPromiseRejectBlock)reject);
RCT_EXTERN_METHOD(removeBottlenecks:(NSString *)fromField fromModel:(NSString *)fromModel resolve:(RCTPromiseResolveBlock)resolve reject:(RCTPromiseRejectBlock)reject);
RCT_EXTERN_METHOD(setRegion:(NSString *)region rectDic:(NSDictionary *)rectDic resolve:(RCTPromiseResolveBlock)resolve reject:(RCTPromiseRejectBlock)reject);
RCT_EXTERN_METHOD(removeRegion:(NSString *)region resolve:(RCTPromiseResolveBlock)resolve reject:(RCTPromiseRejectBlock)reject);
RCT_EXTERN_METHOD(saveMultiArraykey:(NSString *)key resolve:(RCTPromiseResolveBlock)resolve reject:(RCTPromiseRejectBlock)reject);
@end
@interface RCT_EXTERN_MODULE(RHDVisionImageViewManager, RCTViewManager)
RCT_EXPORT_VIEW_PROPERTY(id, NSString *);
@end
@interface RCT_EXTERN_MODULE(RHDVisionCameraViewManager, RCTViewManager)
RCT_EXPORT_VIEW_PROPERTY(gravity, NSString *);
@end