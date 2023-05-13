package com.JustPassMeReactNative

import android.app.Activity
import android.content.Intent
import android.util.Base64
import android.util.Log
import android.widget.Toast
import com.facebook.react.bridge.ActivityEventListener
import com.facebook.react.bridge.Arguments
import com.facebook.react.bridge.BaseActivityEventListener
import com.facebook.react.bridge.Promise
import com.facebook.react.bridge.ReactApplicationContext
import com.facebook.react.bridge.ReactContextBaseJavaModule
import com.facebook.react.bridge.ReactMethod
import com.facebook.react.bridge.ReadableMap
import com.google.android.gms.fido.Fido
import com.google.android.gms.fido.fido2.Fido2ApiClient
import com.google.android.gms.fido.fido2.api.common.Attachment
import com.google.android.gms.fido.fido2.api.common.AuthenticationExtensions
import com.google.android.gms.fido.fido2.api.common.AuthenticatorAssertionResponse
import com.google.android.gms.fido.fido2.api.common.AuthenticatorAttestationResponse
import com.google.android.gms.fido.fido2.api.common.AuthenticatorErrorResponse
import com.google.android.gms.fido.fido2.api.common.AuthenticatorSelectionCriteria
import com.google.android.gms.fido.fido2.api.common.PublicKeyCredential
import com.google.android.gms.fido.fido2.api.common.PublicKeyCredentialCreationOptions
import com.google.android.gms.fido.fido2.api.common.PublicKeyCredentialParameters
import com.google.android.gms.fido.fido2.api.common.PublicKeyCredentialRequestOptions
import com.google.android.gms.fido.fido2.api.common.PublicKeyCredentialRpEntity
import com.google.android.gms.fido.fido2.api.common.PublicKeyCredentialUserEntity
import com.google.android.gms.fido.fido2.api.common.ResidentKeyRequirement
import com.google.android.gms.fido.fido2.api.common.UserVerificationMethodExtension

class JustPassMeReactNativeModule(private val reactContext: ReactApplicationContext) :
  ReactContextBaseJavaModule(reactContext) {


  private val mActivityEventListener: ActivityEventListener = object : BaseActivityEventListener() {
    override fun onActivityResult(
      activity: Activity?, requestCode: Int, resultCode: Int, data: Intent?
    ) {
      super.onActivityResult(activity, requestCode, resultCode, data)
      handleRegistrationResponse(requestCode, resultCode, data, activity)
      handleSignInResponse(requestCode, resultCode, data, activity)
    }
  }

  private fun handleSignInResponse(
    requestCode: Int, resultCode: Int, data: Intent?, activity: Activity?
  ) {
    if (requestCode == AUTH_REQUEST_CODE) {
      if (resultCode != Activity.RESULT_OK) {
        promise?.reject(null, "User Canceled")
      } else {
        val bytes = data?.getByteArrayExtra(Fido.FIDO2_KEY_CREDENTIAL_EXTRA);
        if (bytes == null) {
          promise?.reject(null, "Credential SignIn Error")
        } else {
          try {
            val credential = PublicKeyCredential.deserializeFromBytes(bytes)
            val response = credential.response
            val assertionResponse = credential.response as AuthenticatorAssertionResponse
            if (response is AuthenticatorErrorResponse) {
              promise?.reject(null, response.errorMessage)
            } else {
              val map = Arguments.createMap()
              val rawId = credential.rawId.toBase64()
              map.putString("id", rawId)
              map.putString("rawId", rawId)
              map.putString("type", "public-key")
              val responseMap = Arguments.createMap()
              responseMap.putString(
                "authenticatorData", assertionResponse.authenticatorData.toBase64()
              )
              responseMap.putString("signature", assertionResponse.signature.toBase64())
              responseMap.putString("userHandle", assertionResponse.userHandle?.toBase64())
              responseMap.putString("clientDataJSON", assertionResponse.clientDataJSON.toBase64())
              map.putMap("response", responseMap)
              Log.v("WebAuthn", map.toString())
              Toast.makeText(activity, "Success Auth with Webauthn $map", Toast.LENGTH_LONG).show()
              promise?.resolve(map)
            }
          } catch (e: Exception) {
            Toast.makeText(activity, "Error $e", Toast.LENGTH_LONG).show()
            promise?.reject(null, e);
          }
        }
      }
    }
  }

  private fun handleRegistrationResponse(
    requestCode: Int, resultCode: Int, data: Intent?, activity: Activity?
  ) {
    if (requestCode == REGISTRATION_REQUEST_CODE) {
      if (resultCode != Activity.RESULT_OK) {
        promise?.reject(null, "User Canceled")
      } else {
        val bytes = data?.getByteArrayExtra(Fido.FIDO2_KEY_CREDENTIAL_EXTRA);
        if (bytes == null) {
          promise?.reject(null, "Credential Registration Error")
        } else {
          try {
            val credential = PublicKeyCredential.deserializeFromBytes(bytes)
            val response = credential.response
            if (response is AuthenticatorErrorResponse) {
              promise?.reject(null, response.errorMessage)
            } else {
              val attestationResponse = credential.response as AuthenticatorAttestationResponse
              val map = Arguments.createMap()
              val rawId = credential.rawId.toBase64()
              map.putString("id", rawId)
              map.putString("rawId", rawId)
              map.putString("type", "public-key")
              val responseMap = Arguments.createMap()
              responseMap.putString("clientDataJSON", response.clientDataJSON.toBase64())
              responseMap.putString(
                "attestationObject",
                attestationResponse.attestationObject.toBase64()
              )
              map.putMap("response", responseMap)
              Log.v("WebAuthn", map.toString())
              Toast.makeText(activity, "Success Auth with Webauthn $map", Toast.LENGTH_LONG).show()
              promise?.resolve(map)
            }
          } catch (e: Exception) {
            Toast.makeText(activity, "Error $e", Toast.LENGTH_LONG).show()
            promise?.reject(null, e);
          }
        }
      }
    }
  }

  init {
    reactContext.addActivityEventListener(mActivityEventListener)
  }

  private var promise: Promise? = null
  private var fido2ApiClient: Fido2ApiClient? = Fido.getFido2ApiClient(reactContext);
  private val REGISTRATION_REQUEST_CODE = 2222
  private val AUTH_REQUEST_CODE = 8888
  override fun getName(): String {
    return NAME
  }

  override fun getConstants() = mapOf(
    "isAvailable" to true
  )

  private fun parseCreationOptions(creationOptionsJSON: ReadableMap): PublicKeyCredentialCreationOptions {
    println("PassKey Map:  $creationOptionsJSON")
    val builder = PublicKeyCredentialCreationOptions.Builder()
    builder.setChallenge(creationOptionsJSON.getString("challenge")!!.decodeBase64())
    val user = creationOptionsJSON.getMap("user")
    builder.setUser(
      PublicKeyCredentialUserEntity(
        user?.getString("id")?.decodeBase64()!!, user.getString("name")!!, null.toString(), // icon
        user.getString("displayName") ?: ""
      )
    )
    val rp = creationOptionsJSON.getMap("rp")
    builder.setRp(
      PublicKeyCredentialRpEntity(
        rp?.getString("id")!!, rp.getString("name")!!,/* icon */ null
      )
    )
    val pubKeyCredParams = creationOptionsJSON.getArray("pubKeyCredParams")?.toArrayList()
    if (pubKeyCredParams != null) {
      val parameters = mutableListOf<PublicKeyCredentialParameters>()
      for (param in pubKeyCredParams) {
        if (param is ReadableMap) {
          parameters.add(
            PublicKeyCredentialParameters(
              param.getString("type")!!, param.getInt("alg")
            )
          )
        }
      }
      builder.setParameters(parameters)
    }
    val authenticatorSelection = creationOptionsJSON.getMap("authenticatorSelection")
    if (authenticatorSelection != null) {
      val selectionBuilder = AuthenticatorSelectionCriteria.Builder()
      selectionBuilder.setAttachment(
        Attachment.fromString(authenticatorSelection.getString("authenticatorAttachment")!!)
      )
      selectionBuilder.setResidentKeyRequirement(
        ResidentKeyRequirement.fromString(
          authenticatorSelection.getString("residentKey")!!
        )
      )
      builder.setAuthenticatorSelection(selectionBuilder.build())
    }
    return builder.build()
  }

  @ReactMethod
  fun startRegistration(creationOptionsJSON: ReadableMap, promise: Promise) {
    this.promise = promise
    fido2ApiClient?.let { client ->
      try {
        val requestOptions = parseCreationOptions(creationOptionsJSON)
        val task = client.getRegisterPendingIntent(requestOptions)
        task.addOnSuccessListener {
          if (it != null) {
            val activity = reactContext.currentActivity!!
            activity.startIntentSenderForResult(
              it.intentSender, REGISTRATION_REQUEST_CODE, null, 0, 0, 0
            )
          }
        }
      } catch (e: Exception) {
        promise.reject(null, e)
      }
    }
  }

  companion object {
    const val NAME = "JustPassMeReactNative"
  }


  @ReactMethod
  fun startAuthentication(requestOptionsJSON: ReadableMap, autoFill: Boolean, promise: Promise) {
    this.promise = promise
    fido2ApiClient?.let { client ->
      try {
        val requestOptions = parseCredentialAssertionPublicKey(requestOptionsJSON)
        val task = client.getSignPendingIntent(requestOptions)
        task.addOnSuccessListener {
          if (it != null) {
            val activity = reactContext.currentActivity!!
            activity.startIntentSenderForResult(
              it.intentSender, AUTH_REQUEST_CODE, null, 0, 0, 0
            )
          }
        }
      } catch (e: Exception) {
        promise.reject(null, e)
      }
    }
  }

  private fun parseCredentialAssertionPublicKey(assesOptionsJSON: ReadableMap): PublicKeyCredentialRequestOptions {
    return PublicKeyCredentialRequestOptions.Builder().apply {
      setChallenge(assesOptionsJSON.getString("challenge")!!.decodeBase64())
      setRpId(
        assesOptionsJSON.getString("rpId")!!
      )
      AuthenticationExtensions.Builder().setUserVerificationMethodExtension(
        UserVerificationMethodExtension((true))
      )
    }.build()
  }
}


private const val BASE64_FLAG = Base64.NO_PADDING or Base64.NO_WRAP or Base64.URL_SAFE
fun ByteArray.toBase64(): String {
  return Base64.encodeToString(this, BASE64_FLAG)
}

fun String.decodeBase64(): ByteArray {
  return Base64.decode(this, BASE64_FLAG)
}
