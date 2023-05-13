#import <React/RCTBridgeModule.h>

@interface RCT_EXTERN_MODULE(JustPassMeReactNative, NSObject)

RCT_EXTERN_METHOD(
  startRegistration: (NSString *) registrationURL
  extraClientHeaders: (NSDictionary *) extraClientHeaders
  resolve: (RCTPromiseResolveBlock) resolve
  reject: (RCTPromiseRejectBlock) reject
)
RCT_EXTERN_METHOD(
  startAuthentication: (NSString *) authenticationURL
  extraClientHeaders: (NSDictionary *) extraClientHeaders
  resolve: (RCTPromiseResolveBlock) resolve
  reject: (RCTPromiseRejectBlock) reject
)

@end
