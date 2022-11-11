//
//  AmwalAuthReactNative.swift
//  Amwal
//
//  Created by Sameh Galal on 10/8/22.
//

import Foundation
import AuthenticationServices
import OSLog

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
}

extension Decodable {
  init(from: Any) throws {
    let data = try JSONSerialization.data(withJSONObject: from, options: .prettyPrinted)
    let decoder = JSONDecoder()
    self = try decoder.decode(Self.self, from: data)
  }
}

class RCTPromiseResoveReject: NSObject {
  let resolve : RCTPromiseResolveBlock
  let reject: RCTPromiseRejectBlock
  init(resolve:@escaping RCTPromiseResolveBlock, reject:@escaping RCTPromiseRejectBlock){
    self.resolve = resolve
    self.reject = reject
  }
}

@available(iOS 16.0, *)
@objc(AmwalAuthReactNative)
class AmwalAuthReactNative: NSObject, ASAuthorizationControllerPresentationContextProviding, ASAuthorizationControllerDelegate {
  
  var authenticationAnchor: ASPresentationAnchor?
  var promises: [ASAuthorizationController:RCTPromiseResoveReject] = [:]
  
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
        promises[authController] = RCTPromiseResoveReject(resolve: resolve, reject: reject);
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
        promises[authController] = RCTPromiseResoveReject(resolve: resolve, reject: reject);
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

