#import <React/RCTBridgeModule.h>

@interface RCT_EXTERN_MODULE(AmwalAuthReactNative, NSObject)

RCT_EXTERN_METHOD(
  startRegistration: (NSString *) clientURL
  authServiceURL: (NSString *) authServiceURL
  resolve: (RCTPromiseResolveBlock) resolve
  reject: (RCTPromiseRejectBlock) reject
)
RCT_EXTERN_METHOD(
  startAuthentication: (NSString *) clientURL
  authServiceURL: (NSString *) authServiceURL
  autoFill: (BOOL) autoFill
  resolve: (RCTPromiseResolveBlock) resolve
  reject: (RCTPromiseRejectBlock) reject
)

@end
