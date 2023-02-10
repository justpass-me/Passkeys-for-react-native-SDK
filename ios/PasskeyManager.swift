import Combine
import AuthenticationServices

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

@available(iOS 16.0, *)
final class PasskeyManager: NSObject, ASAuthorizationControllerPresentationContextProviding, ASAuthorizationControllerDelegate {
  private typealias RegistrationCheckedThrowingContinuation = CheckedContinuation<ASAuthorizationPlatformPublicKeyCredentialRegistration, Error>
  private typealias AuthenticationCheckedThrowingContinuation = CheckedContinuation<ASAuthorizationPlatformPublicKeyCredentialAssertion, Error>

  private var presentationAnchor: ASPresentationAnchor?
  private var registrationCheckedThrowingContinuation: RegistrationCheckedThrowingContinuation?
  private var authenticationCheckedThrowingContinuation: AuthenticationCheckedThrowingContinuation?

  init(presentationAnchor :ASPresentationAnchor){
    self.presentationAnchor = presentationAnchor
  }

  func register(_ creationOptionsJSON: NSDictionary) async throws -> ASAuthorizationPlatformPublicKeyCredentialRegistration {
    return try await withCheckedThrowingContinuation({ [weak self] (continuation:  RegistrationCheckedThrowingContinuation) in
        do {
            guard let self = self else {
                return
            }
            self.registrationCheckedThrowingContinuation = continuation
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
            authController.delegate = self
            authController.presentationContextProvider = self
            authController.performRequests()
        } catch {
            self?.registrationCheckedThrowingContinuation?.resume(throwing: error)
        }
    })
  }

  func authenticate(_
    requestOptionsJSON: NSDictionary,
    autoFill: Bool) async throws -> ASAuthorizationPlatformPublicKeyCredentialAssertion {
    return try await withCheckedThrowingContinuation({ [weak self] (continuation: AuthenticationCheckedThrowingContinuation) in
        do {
            guard let self = self else {
                return
            }
            self.authenticationCheckedThrowingContinuation = continuation
            let assertionRequestOptions = try CredentialAssertionPublicKey(from: requestOptionsJSON);
            let challenge = assertionRequestOptions.challenge.decodeBase64Url()!
            let rpId = assertionRequestOptions.rpId
            let publicKeyCredentialProvider = ASAuthorizationPlatformPublicKeyCredentialProvider(relyingPartyIdentifier: rpId)
            let assertionRequest = publicKeyCredentialProvider.createCredentialAssertionRequest(challenge: challenge)
            
            if let userVerification = assertionRequestOptions.userVerification {
              assertionRequest.userVerificationPreference = ASAuthorizationPublicKeyCredentialUserVerificationPreference.init(rawValue: userVerification)
            }
            let authController = ASAuthorizationController(authorizationRequests: [ assertionRequest ] )
            authController.delegate = self
            authController.presentationContextProvider = self
            if (autoFill) {
              authController.performAutoFillAssistedRequests();
            } else {
              authController.performRequests(options: .preferImmediatelyAvailableCredentials);
            }
            
        } catch {
            self?.authenticationCheckedThrowingContinuation?.resume(throwing: error)
        }
    })
  }

  func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
    return self.presentationAnchor!
  }

  func authorizationController(
    controller: ASAuthorizationController,
    didCompleteWithAuthorization authorization: ASAuthorization) {

      switch authorization.credential {

        case let credentialRegistration as ASAuthorizationPlatformPublicKeyCredentialRegistration:
          self.registrationCheckedThrowingContinuation?.resume(returning: credentialRegistration)
          self.registrationCheckedThrowingContinuation = nil
          
        case let credentialAssertion as ASAuthorizationPlatformPublicKeyCredentialAssertion:
          self.authenticationCheckedThrowingContinuation?.resume(returning: credentialAssertion)
          self.authenticationCheckedThrowingContinuation = nil
          
        default:
          fatalError("Received unknown authorization type.")
      }
  }
  
  func authorizationController(
    controller: ASAuthorizationController,
    didCompleteWithError error: Error) {
      self.registrationCheckedThrowingContinuation?.resume(throwing: error)
      self.registrationCheckedThrowingContinuation = nil
  }
}
