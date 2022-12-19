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

class CredentialCreationPublicKey : Codable {
  var challenge: String
  var user: CredentialCreationUser
  var rp: CredentialCreationRpEntity
  var attestation: String?
  var authenticatorSelection: CredentialCreationAuthenticatorSelection?
}

class CredentialCreationRpEntity : Codable {
  var id: String
  var name: String
}

class CredentialCreationUser : Codable {
  var id: String
  var name: String
  var displayName: String
}

class CredentialCreationAuthenticatorSelection : Codable {
  var userVerification: String?
  var authenticatorAttachment: String?
  var residentKey: String?
  var requireResidentKey: Bool?
}

class CredentialAssertionPublicKey : Codable {
  var challenge: String
  var rpId: String
  var userVerification: String?
}

extension String {
  func decodeBase64Url() -> Data? {
    var base64 = self
      .replacingOccurrences(of: "-", with: "+")
      .replacingOccurrences(of: "_", with: "/")
    if base64.count % 4 != 0 {
      base64.append(String(repeating: "=", count: 4 - base64.count % 4))
    }
    return Data(base64Encoded: base64)
  }
}

extension Data {
  func toBase64Url() -> String {
    return self.base64EncodedString().replacingOccurrences(of: "+", with: "-").replacingOccurrences(of: "/", with: "_").replacingOccurrences(of: "=", with: "")
  }

  func hexEncodedString() -> String {
    return self.map { String(format: "%02hhX", $0) }.joined()
  }
}

extension Decodable {
  init(from: Any) throws {
    let data = try JSONSerialization.data(withJSONObject: from, options: .prettyPrinted)
    let decoder = JSONDecoder()
    self = try decoder.decode(Self.self, from: data)
  }
}

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
class AmwalAuthReactNative: NSObject, ASAuthorizationControllerPresentationContextProviding, ASAuthorizationControllerDelegate {
  
  var authenticationAnchor: ASPresentationAnchor?
  var promises: [ASAuthorizationController:RCTPromiseResolveReject] = [:]
  
  @objc static func requiresMainQueueSetup() -> Bool { return true }
  
  @objc public func constantsToExport() -> NSDictionary {
    return ["isAvailable": true];
  }
  
  func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
    return self.authenticationAnchor!
  }
  
  @objc public func startRegistration(_
    creationOptionsJSON: NSDictionary,
    resolve:@escaping RCTPromiseResolveBlock,
    reject:@escaping RCTPromiseRejectBlock) {
      
      self.authenticationAnchor = RCTPresentedViewController()?.view.window;
      do {
        let creationRequest = try CredentialCreationPublicKey(from: creationOptionsJSON)
        let challenge = creationRequest.challenge.decodeBase64Url()!
        let userID = creationRequest.user.id.decodeBase64Url()!
        let publicKeyCredentialProvider = ASAuthorizationPlatformPublicKeyCredentialProvider(relyingPartyIdentifier: creationRequest.rp.id)
        let registrationRequest = publicKeyCredentialProvider.createCredentialRegistrationRequest(challenge: challenge, name: creationRequest.user.name, userID: userID)
        if let attestation = creationRequest.attestation {
          registrationRequest.attestationPreference = ASAuthorizationPublicKeyCredentialAttestationKind.init(rawValue: attestation)
        }
        if let userVerification = creationRequest.authenticatorSelection?.userVerification {
          registrationRequest.userVerificationPreference = ASAuthorizationPublicKeyCredentialUserVerificationPreference.init(rawValue: userVerification)
        }
        let authController = ASAuthorizationController(authorizationRequests: [ registrationRequest ] )
        promises[authController] = RCTPromiseResolveReject(resolve: resolve, reject: reject);
        authController.delegate = self
        authController.presentationContextProvider = self
        authController.performRequests()
      } catch {
        reject("AmwalAuth",error.localizedDescription, error)
      }
  }
  
  @objc public func startAuthentication(_
    requestOptionsJSON: NSDictionary,
    autoFill: Bool,
    resolve:@escaping RCTPromiseResolveBlock,
    reject:@escaping RCTPromiseRejectBlock) {
      
      self.authenticationAnchor = RCTPresentedViewController()?.view.window;
      do {
        let assertionRequestOptions = try CredentialAssertionPublicKey(from: requestOptionsJSON);
        let challenge = assertionRequestOptions.challenge.decodeBase64Url()!
        let rpId = assertionRequestOptions.rpId
        let publicKeyCredentialProvider = ASAuthorizationPlatformPublicKeyCredentialProvider(relyingPartyIdentifier: rpId)
        let assertionRequest = publicKeyCredentialProvider.createCredentialAssertionRequest(challenge: challenge)
        
        if let userVerification = assertionRequestOptions.userVerification {
          assertionRequest.userVerificationPreference = ASAuthorizationPublicKeyCredentialUserVerificationPreference.init(rawValue: userVerification)
        }
        let authController = ASAuthorizationController(authorizationRequests: [ assertionRequest ] )
        promises[authController] = RCTPromiseResolveReject(resolve: resolve, reject: reject);
        authController.delegate = self
        authController.presentationContextProvider = self
        if (autoFill) {
          authController.performAutoFillAssistedRequests();
        } else {
          authController.performRequests(options: .preferImmediatelyAvailableCredentials);
        }
      } catch {
        reject("AmwalAuth",error.localizedDescription, error)
      }
  }

  static var registerNotificationResolveReject : RCTPromiseResolveReject? = nil

  @objc public func registerNotification(_
    resolve:@escaping RCTPromiseResolveBlock,
    reject:@escaping RCTPromiseRejectBlock){
      DispatchQueue.main.async{
        if case .uninitialized = AmwalAuthReactNative.successSwizzleState {
          self.swizzleDidReceiveRemoteNotification();
        }
        if case .uninitialized = AmwalAuthReactNative.failureSwizzleState {
          self.swizzleDidFailToRegisterForRemoteNotification();
        }
        UIApplication.shared.registerForRemoteNotifications();
        AmwalAuthReactNative.registerNotificationResolveReject = RCTPromiseResolveReject(resolve: resolve, reject: reject);
      }
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

  static var successSwizzleState = SwizzlingState.uninitialized;

  private func swizzleDidReceiveRemoteNotification() {
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
  
  func authorizationController(
    controller: ASAuthorizationController,
    didCompleteWithAuthorization authorization: ASAuthorization) {
      
      let logger = Logger()
      switch authorization.credential {
      
      case let credentialRegistration as ASAuthorizationPlatformPublicKeyCredentialRegistration:
        logger.log("A new credential was registered: \(credentialRegistration)")
        promises[controller]?.resolve([
          "id": credentialRegistration.credentialID.toBase64Url(),
          "rawId": credentialRegistration.credentialID.toBase64Url(),
          "type": "public-key",
          "response": [
            "attestationObject": credentialRegistration.rawAttestationObject!.toBase64Url(),
            "clientDataJSON": credentialRegistration.rawClientDataJSON.toBase64Url()
          ]
        ])
        
      case let credentialAssertion as ASAuthorizationPlatformPublicKeyCredentialAssertion:
        logger.log("A credential was used to authenticate: \(credentialAssertion)")
        promises[controller]?.resolve([
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
        
      default:
        fatalError("Received unknown authorization type.")
      }
      promises.removeValue(forKey: controller);
  }
  
  func authorizationController(
    controller: ASAuthorizationController,
    didCompleteWithError error: Error) {
      
      let logger = Logger()
      guard let authorizationError = ASAuthorizationError.Code(rawValue: (error as NSError).code) else {
        logger.error("Unexpected authorization error: \(error.localizedDescription)")
        return
      }
      if authorizationError == .canceled {
        // Either no credentials were found and the request silently ended, or the user canceled the request.
        // Consider asking the user to create an account.
        logger.log("Request canceled.")
      } else {
        // Other ASAuthorization error.
        // The userInfo dictionary should contain useful information.
        logger.error("Error: \((error as NSError).userInfo)")
      }
      promises[controller]?.reject("AmwalAuth", error.localizedDescription, error)
      promises.removeValue(forKey: controller)
  }
}

