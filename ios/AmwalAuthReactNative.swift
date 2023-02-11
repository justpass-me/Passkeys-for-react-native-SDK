//
//  AmwalAuthReactNative.swift
//  Amwal
//
//  Created by Sameh Galal on 10/8/22.
//

import Foundation
import AuthenticationServices

@available(iOS 16.0, *)
@objc(AmwalAuthReactNative)
class AmwalAuthReactNative: NSObject {
  
  @objc static func requiresMainQueueSetup() -> Bool { return true }
  
  @objc public func constantsToExport() -> [AnyHashable : Any] {
    return ["isAvailable": true];
  }
  
  @objc public func startRegistration(_
    clientURL: String,
    authServiceURL: String,
    resolve:@escaping RCTPromiseResolveBlock,
    reject:@escaping RCTPromiseRejectBlock) {
      Task{
          do {
            let amwalAuthClient = await AmwalAuthClient(clientURL: clientURL,
                                                    authServiceURL: authServiceURL,
                                                    presentationAnchor: (RCTPresentedViewController()?.view.window)!);
            let result = try await amwalAuthClient.register();
            resolve(result)
          } catch {
            reject("AmwalAuth",error.localizedDescription, error)
          }
      }
  }
  
  @objc public func startAuthentication(_
    clientURL: String,
    authServiceURL: String,
    autoFill: Bool,
    resolve:@escaping RCTPromiseResolveBlock,
    reject:@escaping RCTPromiseRejectBlock) {
      Task{
          do {
            let amwalAuthClient = await AmwalAuthClient(clientURL: clientURL,
                                                    authServiceURL: authServiceURL,
                                                    presentationAnchor: (RCTPresentedViewController()?.view.window)!);
            let result = try await amwalAuthClient.authenticate(autoFill: autoFill);
            resolve(result)
          } catch {
            reject("AmwalAuth",error.localizedDescription, error)
          }
      }
  }
}
