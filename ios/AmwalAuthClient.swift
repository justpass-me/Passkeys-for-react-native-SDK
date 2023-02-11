import AuthenticationServices


@available(iOS 16.0, *)
final class AmwalAuthClient: NSObject {

  enum AmwalAuthClientError: Error {
    case badResponse
    case runtimeError(String)
  }

  private var authServiceURL: String
  private var clientURL: String
    private var passkeyManager: PasskeyManager

  init(clientURL: String, authServiceURL: String, presentationAnchor :ASPresentationAnchor){
    self.authServiceURL = authServiceURL
    self.clientURL = clientURL
    self.passkeyManager = PasskeyManager(presentationAnchor: presentationAnchor)
  }

  func register() async throws -> NSDictionary {

    var urlRequest = URLRequest(url: URL(string: "\(self.clientURL)/oidc/authenticate/")! )

    urlRequest.setValue("app", forHTTPHeaderField: "AMWAL-PLATFORM")

    let (data, _) = try await URLSession.shared.data(for: urlRequest)

    let startRegistrationResponse = try! JSONSerialization.jsonObject(with: data) as? NSDictionary;

      let credentialRegistration = try await passkeyManager.register(startRegistrationResponse?["publicKey"] as! NSDictionary);

    var request = URLRequest(url: URL(string: "\(self.authServiceURL)/fido2/reg_complete/")!)
    request.httpMethod = "POST"
    request.addValue("application/json", forHTTPHeaderField: "Content-Type")
    request.httpBody = try? JSONSerialization.data(withJSONObject: [
      "id": credentialRegistration.credentialID.toBase64Url(),
      "rawId": credentialRegistration.credentialID.toBase64Url(),
      "type": "public-key",
      "response": [
        "attestationObject": credentialRegistration.rawAttestationObject!.toBase64Url(),
        "clientDataJSON": credentialRegistration.rawClientDataJSON.toBase64Url()
      ]
    ])

    let (regData, _) = try await URLSession.shared.data(for: request)

    guard let completeRegistrationResponse = try! JSONSerialization.jsonObject(with: regData) as? NSDictionary else {
        throw AmwalAuthClientError.badResponse;
    };
    
    if (completeRegistrationResponse["status"] as? String == "ERR") {
        throw AmwalAuthClientError.runtimeError(completeRegistrationResponse["message"] as! String);
    }

    var backUrlRequest = URLRequest(url: URL(string: "\(self.authServiceURL)/back_to_client/")! )
    backUrlRequest.setValue("app", forHTTPHeaderField: "AMWAL-PLATFORM")
    let (backData, _) = try await URLSession.shared.data(for: backUrlRequest)
    guard let backResponse = try? JSONSerialization.jsonObject(with: backData) as? NSDictionary else {
      throw AmwalAuthClientError.badResponse;
    };
    return backResponse;
  }
    
  func authenticate(autoFill: Bool) async throws -> NSDictionary {

    var urlRequest = URLRequest(url: URL(string: "\(self.clientURL)/oidc/authenticate/")! )

    urlRequest.setValue("app", forHTTPHeaderField: "AMWAL-PLATFORM")

    let (data, _) = try await URLSession.shared.data(for: urlRequest)

    let startAuthenticationResponse = try! JSONSerialization.jsonObject(with: data) as? NSDictionary;

    let credentialAssertion = try await passkeyManager.authenticate(startAuthenticationResponse?["publicKey"] as! NSDictionary, autoFill: autoFill);

    var request = URLRequest(url: URL(string: "\(self.authServiceURL)/fido2/complete_auth/")!)
    request.httpMethod = "POST"
    request.addValue("application/json", forHTTPHeaderField: "Content-Type")
    request.httpBody = try? JSONSerialization.data(withJSONObject: [
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

    let (authData, _) = try await URLSession.shared.data(for: request)

    guard let completeAuthenticationResponse = try! JSONSerialization.jsonObject(with: authData) as? NSDictionary else {
        throw AmwalAuthClientError.badResponse;
    };
    
    if (completeAuthenticationResponse["status"] as? String == "ERR") {
        throw AmwalAuthClientError.runtimeError(completeAuthenticationResponse["message"] as! String);
    }

    var backUrlRequest = URLRequest(url: URL(string: "\(self.authServiceURL)/back_to_client/")! )
    backUrlRequest.setValue("app", forHTTPHeaderField: "AMWAL-PLATFORM")
    let (backData, _) = try await URLSession.shared.data(for: backUrlRequest)
    guard let backResponse = try? JSONSerialization.jsonObject(with: backData) as? NSDictionary else {
      throw AmwalAuthClientError.badResponse;
    };
    return backResponse;
  }
}
