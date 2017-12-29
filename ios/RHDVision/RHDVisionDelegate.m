#import <React/RCTBridgeModule.h>
#import <React/RCTEventEmitter.h>

@interface RCT_EXTERN_MODULE(RHDVisionModule, RCTEventEmitter)
RCT_EXTERN_METHOD(attach)
RCT_EXTERN_METHOD(saveFrame:(NSString *)description resolve: (RCTPromiseResolveBlock)resolve reject:(RCTPromiseRejectBlock)reject)
RCT_EXTERN_METHOD(detectFaces: (RCTPromiseResolveBlock)resolve reject:(RCTPromiseRejectBlock)reject)
RCT_EXTERN_METHOD(trackObject: (NSString *)name dict:(NSDictionary *)dict resolve: (RCTPromiseResolveBlock)resolve reject:(RCTPromiseRejectBlock)reject)
@end
