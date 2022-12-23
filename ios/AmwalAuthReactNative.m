#import <React/RCTBridgeModule.h>

@interface RCT_EXTERN_MODULE(AmwalAuthReactNative, NSObject)

RCT_EXTERN_METHOD(
  startRegistration: (NSDictionary *) creationOptionsJSON
  resolve: (RCTPromiseResolveBlock) resolve
  reject: (RCTPromiseRejectBlock) reject
)
RCT_EXTERN_METHOD(
  startAuthentication: (NSDictionary *) requestOptionsJSON
  autoFill: (BOOL) autoFill
  resolve: (RCTPromiseResolveBlock) resolve
  reject: (RCTPromiseRejectBlock) reject
)

RCT_EXTERN_METHOD(
  presentAuthenticationModal: (NSDictionary *) requestOptionsJSON
  modalContent: (NSString *) modalContent
  resolve: (RCTPromiseResolveBlock) resolve
  reject: (RCTPromiseRejectBlock) reject
)

RCT_EXTERN_METHOD(
  registerNotification: (RCTPromiseResolveBlock) resolve
  reject: (RCTPromiseRejectBlock) reject
)

RCT_EXTERN_METHOD(
  setNotificationMessageCallback: (RCTResponseSenderBlock) callback
)

@end
