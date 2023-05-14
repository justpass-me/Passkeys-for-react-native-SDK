//
//  JustPassMeReactNative.swift
//
//  Created by Sameh Galal on 10/8/22.
//

import Foundation
import AuthenticationServices
import JustPassMeFramework

@available(iOS 16.0, *)
@objc(JustPassMeReactNative)
class JustPassMeReactNative: NSObject {
  
  @objc static func requiresMainQueueSetup() -> Bool { return true }
  
  @objc public func constantsToExport() -> [AnyHashable : Any] {
    return ["isAvailable": true];
  }

  func handleJustPassMeClientError(_ error: Error, reject: RCTPromiseRejectBlock) {
    let customError = error as? JustPassMeClient.JustPassMeClientError
    switch customError {
    case .badURL:
        reject("JustPassMe", "Bad URL", error)
    case .badResponse:
        reject("JustPassMe", "Bad response", error)
    case .noPublicKey:
        reject("JustPassMe", "No public key", error)
    case .runtimeError(let errorMessage):
        reject("JustPassMe", errorMessage, error)
    case .none:
        let nsError = error as NSError
        reject("JustPassMe", nsError.localizedDescription, nsError)
    }
  }
  
  @objc public func startRegistration(_
    registrationURL: String,
    extraClientHeaders: NSDictionary,
    resolve:@escaping RCTPromiseResolveBlock,
    reject:@escaping RCTPromiseRejectBlock) {
      let swiftDict = extraClientHeaders as? [String: String]
      Task{
          do {
            let JustPassMeClient = await JustPassMeClient(presentationAnchor: (RCTPresentedViewController()?.view.window)!);
              let result = try await JustPassMeClient.register(
                                registrationURL: registrationURL,
                                extraClientHeaders: swiftDict);
            resolve(result)
          } catch {
            handleJustPassMeClientError(error, reject: reject)
          }
      }
  }
  
  @objc public func startAuthentication(_
    authenticationURL: String,
    extraClientHeaders: NSDictionary,
    resolve:@escaping RCTPromiseResolveBlock,
    reject:@escaping RCTPromiseRejectBlock) {
      let swiftDict = extraClientHeaders as? [String: String]
      Task{
          do {
            let JustPassMeClient = await JustPassMeClient(presentationAnchor: (RCTPresentedViewController()?.view.window)!);
            let result = try await JustPassMeClient.authenticate(
                                authenticationURL: authenticationURL,
                                extraClientHeaders: swiftDict);
            resolve(result)
          } catch {
            handleJustPassMeClientError(error, reject: reject)
          }
      }
  }
}
