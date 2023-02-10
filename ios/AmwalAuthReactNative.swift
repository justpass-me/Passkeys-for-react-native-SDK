//
//  AmwalAuthReactNative.swift
//  Amwal
//
//  Created by Sameh Galal on 10/8/22.
//

import Foundation
import AuthenticationServices
import OSLog
import SwiftUI

class RCTPromiseResolveReject: NSObject {
  let resolve : RCTPromiseResolveBlock
  let reject: RCTPromiseRejectBlock
  init(resolve:@escaping RCTPromiseResolveBlock, reject:@escaping RCTPromiseRejectBlock){
    self.resolve = resolve
    self.reject = reject
  }
}

@available(iOS 15.0, *)
struct FullScreenModalView: View {
    var approveHandler: () -> Void
    var dismissHandler: () -> Void
    var modalContent: String
    @Environment(\.dismiss) var dismiss

    var body: some View {
        VStack {
            Text(modalContent)
            HStack{
                Button("Cancel", role: .cancel) {
                    dismissHandler()
                    dismiss()
                }
                Button("Approve"){
                    approveHandler()
                    dismiss()
                }
            }
        }
    }
}

enum SwizzlingState {
    case uninitialized, added, swizzled
}

@available(iOS 16.0, *)
@objc(AmwalAuthReactNative)
class AmwalAuthReactNative: RCTEventEmitter {
  
  var passkeyManager = PasskeyManager(presentationAnchor: (RCTPresentedViewController()?.view.window)!)
  
  @objc override static func requiresMainQueueSetup() -> Bool { return true }
  
  @objc public override func constantsToExport() -> [AnyHashable : Any] {
    return ["isAvailable": true];
  }

  @objc override func supportedEvents() -> [String]! {
      return ["AmwalAuthNotificationEvent"]
  }
  
  @objc public func startRegistration(_
    creationOptionsJSON: NSDictionary,
    resolve:@escaping RCTPromiseResolveBlock,
    reject:@escaping RCTPromiseRejectBlock) {
      Task{
          do {
            let credentialRegistration = try await passkeyManager.register(creationOptionsJSON)
            resolve([
              "id": credentialRegistration.credentialID.toBase64Url(),
              "rawId": credentialRegistration.credentialID.toBase64Url(),
              "type": "public-key",
              "response": [
                "attestationObject": credentialRegistration.rawAttestationObject!.toBase64Url(),
                "clientDataJSON": credentialRegistration.rawClientDataJSON.toBase64Url()
              ]
            ])
          } catch {
            reject("AmwalAuth",error.localizedDescription, error)
          }
      }
  }
  
  @objc public func startAuthentication(_
    requestOptionsJSON: NSDictionary,
    autoFill: Bool,
    resolve:@escaping RCTPromiseResolveBlock,
    reject:@escaping RCTPromiseRejectBlock) {
      Task{
          do {
              let credentialAssertion = try await passkeyManager.authenticate(requestOptionsJSON, autoFill: autoFill)
              resolve([
                "id": credentialAssertion.credentialID.toBase64Url(),
                "rawId": credentialAssertion.credentialID.toBase64Url(),
                "type": "public-key",
                "response": [
                    "authenticatorData": credentialAssertion.rawAuthenticatorData.toBase64Url(),
                    "clientDataJSON": credentialAssertion.rawClientDataJSON.toBase64Url(),
                    "signature": credentialAssertion.signature.toBase64Url(),
                    "userHandle": credentialAssertion.userID.toBase64Url(),
                ]
              ])
              
          } catch {
              reject("AmwalAuth",error.localizedDescription, error)
          }
      }
  }

  static var registerNotificationResolveReject : RCTPromiseResolveReject? = nil
  static var remoteNotificationEventEmitter : RCTEventEmitter? = nil
  static var remoteNotificationCallback: RCTResponseSenderBlock? = nil

  @objc public func registerNotification(_
    resolve:@escaping RCTPromiseResolveBlock,
    reject:@escaping RCTPromiseRejectBlock){
    UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
      if let error = error {
        // Handle the error here.
        reject("AmwalAuth",error.localizedDescription, error);
      } else {
        // Enable or disable features based on the authorization.
        DispatchQueue.main.async{
          if case .uninitialized = AmwalAuthReactNative.successSwizzleState {
            self.swizzleDidRegisterForRemoteNotification();
          }
          if case .uninitialized = AmwalAuthReactNative.failureSwizzleState {
            self.swizzleDidFailToRegisterForRemoteNotification();
          }
          if case .uninitialized = AmwalAuthReactNative.handlerSwizzleState {
            self.swizzleDidReceiveRemoteNotification();
          }
          UIApplication.shared.registerForRemoteNotifications();
          AmwalAuthReactNative.registerNotificationResolveReject = RCTPromiseResolveReject(resolve: resolve, reject: reject);
          AmwalAuthReactNative.remoteNotificationEventEmitter = self;
        }
      }
    }
  }

  @objc public func setNotificationMessageCallback(_
    callback: @escaping RCTResponseSenderBlock) {
    AmwalAuthReactNative.remoteNotificationCallback = callback;
  }

  @objc dynamic class func application(
    _ app: UIApplication,
    didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
  ){
    if case .swizzled = AmwalAuthReactNative.successSwizzleState {
      AmwalAuthReactNative.application(app, didRegisterForRemoteNotificationsWithDeviceToken: deviceToken);
    }
    AmwalAuthReactNative.registerNotificationResolveReject?.resolve(deviceToken.hexEncodedString());
  }

  @objc dynamic class func application(
    _ app: UIApplication,
    didFailToRegisterForRemoteNotificationsWithError error: Error
  ){
    if case .swizzled = AmwalAuthReactNative.failureSwizzleState {
      AmwalAuthReactNative.application(app, didFailToRegisterForRemoteNotificationsWithError: error);
    }
    AmwalAuthReactNative.registerNotificationResolveReject?.reject("AmwalAuth", error.localizedDescription, error)
  }

  @objc dynamic class func application(
    _ app: UIApplication,
    didReceiveRemoteNotification userInfo: [AnyHashable : Any],
    fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void
  ) {
    if case .swizzled = AmwalAuthReactNative.handlerSwizzleState {
      AmwalAuthReactNative.application(app, didReceiveRemoteNotification: userInfo, fetchCompletionHandler: completionHandler);
    }
    AmwalAuthReactNative.remoteNotificationEventEmitter?.sendEvent(withName: "AmwalAuthNotificationEvent", body: userInfo);
    AmwalAuthReactNative.remoteNotificationCallback?([userInfo]);
    AmwalAuthReactNative.remoteNotificationCallback = nil;
  }

  static var successSwizzleState = SwizzlingState.uninitialized;

  private func swizzleDidRegisterForRemoteNotification() {
    let appDelegate = UIApplication.shared.delegate
    let appDelegateClass = type(of: appDelegate!)

    let originalSelector = #selector(UIApplicationDelegate.application(_:didRegisterForRemoteNotificationsWithDeviceToken:))
    let swizzledSelector = #selector(AmwalAuthReactNative.application(_:didRegisterForRemoteNotificationsWithDeviceToken:))

    let swizzledMethod = class_getClassMethod(type(of: self), swizzledSelector)

    if let originalMethod = class_getInstanceMethod(appDelegateClass, originalSelector)  {
      // exchange implementation
      AmwalAuthReactNative.successSwizzleState = .swizzled;
      method_exchangeImplementations(originalMethod, swizzledMethod!)
    } else {
      // add implementation
      AmwalAuthReactNative.successSwizzleState = .added;
      class_addMethod(appDelegateClass, swizzledSelector, method_getImplementation(swizzledMethod!), method_getTypeEncoding(swizzledMethod!))
    }
  }

  static var failureSwizzleState = SwizzlingState.uninitialized;

  private func swizzleDidFailToRegisterForRemoteNotification() {
    let appDelegate = UIApplication.shared.delegate
    let appDelegateClass = type(of: appDelegate!)

    let originalSelector = #selector(UIApplicationDelegate.application(_:didFailToRegisterForRemoteNotificationsWithError:))
    let swizzledSelector = #selector(AmwalAuthReactNative.application(_:didFailToRegisterForRemoteNotificationsWithError:))

    let swizzledMethod = class_getClassMethod(type(of: self), swizzledSelector)

    if let originalMethod = class_getInstanceMethod(appDelegateClass, originalSelector)  {
      // exchange implementation
      AmwalAuthReactNative.failureSwizzleState = .swizzled;
      method_exchangeImplementations(originalMethod, swizzledMethod!)
    } else {
      // add implementation
      AmwalAuthReactNative.failureSwizzleState = .added;
      class_addMethod(appDelegateClass, swizzledSelector, method_getImplementation(swizzledMethod!), method_getTypeEncoding(swizzledMethod!))
    }
  }

  static var handlerSwizzleState = SwizzlingState.uninitialized;

  private func swizzleDidReceiveRemoteNotification() {
    let appDelegate = UIApplication.shared.delegate
    let appDelegateClass = type(of: appDelegate!)

    let originalSelector = #selector(UIApplicationDelegate.application(_:didReceiveRemoteNotification:fetchCompletionHandler:))
    let swizzledSelector = #selector(AmwalAuthReactNative.application(_:didReceiveRemoteNotification:fetchCompletionHandler:))

    let swizzledMethod = class_getClassMethod(type(of: self), swizzledSelector)

    if let originalMethod = class_getInstanceMethod(appDelegateClass, originalSelector)  {
      // exchange implementation
      AmwalAuthReactNative.handlerSwizzleState = .swizzled;
      method_exchangeImplementations(originalMethod, swizzledMethod!)
    } else {
      // add implementation
      AmwalAuthReactNative.handlerSwizzleState = .added;
      class_addMethod(appDelegateClass, swizzledSelector, method_getImplementation(swizzledMethod!), method_getTypeEncoding(swizzledMethod!))
    }
  }

  @objc public func presentAuthenticationModal(_
    requestOptionsJSON: NSDictionary,
    modalContent: String,
    resolve:@escaping RCTPromiseResolveBlock,
    reject:@escaping RCTPromiseRejectBlock) {
    DispatchQueue.main.async{
      RCTPresentedViewController()?
        .present(
          UIHostingController( rootView: FullScreenModalView(
            approveHandler: { [self] in
                startAuthentication(requestOptionsJSON, autoFill: false, resolve: resolve, reject: reject)
            },
            dismissHandler: {
              reject("AmwalAuth", "Modal Dismissed", NSError(domain: "AmwalAuth", code: -5))
            },
            modalContent: modalContent)),
          animated: true)
    }
  }
}
