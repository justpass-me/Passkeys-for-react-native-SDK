package com.amwalauthreactnative

import android.app.Activity
import android.util.Base64
import com.facebook.react.bridge.Arguments
import com.facebook.react.bridge.ReactApplicationContext
import com.facebook.react.bridge.ReactContextBaseJavaModule
import com.facebook.react.bridge.ReactMethod
import com.facebook.react.bridge.Promise
import com.facebook.react.bridge.ReadableMap
import com.facebook.react.bridge.WritableMap
import com.google.android.gms.fido.Fido
import com.google.android.gms.fido.fido2.Fido2ApiClient
import com.google.android.gms.fido.fido2.api.common.*
import androidx.appcompat.app.AppCompatActivity
import androidx.activity.result.ActivityResult
import androidx.activity.result.IntentSenderRequest
import androidx.activity.result.contract.ActivityResultContracts

private const val BASE64_FLAG = Base64.NO_PADDING or Base64.NO_WRAP or Base64.URL_SAFE

fun ByteArray.toBase64(): String {
    return Base64.encodeToString(this, BASE64_FLAG)
}

fun String.decodeBase64(): ByteArray {
    return Base64.decode(this, BASE64_FLAG)
}

class AmwalAuthReactNativeModule(val reactContext: ReactApplicationContext) :
  ReactContextBaseJavaModule(reactContext) {

  private var fido2ApiClient: Fido2ApiClient? = Fido.getFido2ApiClient(reactContext);

  override fun getName(): String {
    return NAME
  }

  override fun getConstants() = mapOf(
    "isAvailable" to true
  )

  private fun parseCreationOptions(creationOptionsJSON: ReadableMap): PublicKeyCredentialCreationOptions {
    val builder = PublicKeyCredentialCreationOptions.Builder()
    builder.setChallenge(creationOptionsJSON.getString("challenge")!!.decodeBase64())
    val user = creationOptionsJSON.getMap("user")
    builder.setUser(PublicKeyCredentialUserEntity(
      user?.getString("id")?.decodeBase64()!!,
      user?.getString("name")!!, 
      null.toString(), // icon
      user?.getString("displayName")?: ""
    ))
    val rp = creationOptionsJSON.getMap("rp")
    builder.setRp(PublicKeyCredentialRpEntity(
      rp?.getString("id")!!,
      rp?.getString("name")!!,
      /* icon */ null
    ))
    val pubKeyCredParams = creationOptionsJSON.getArray("pubKeyCredParams")?.toArrayList()
    if (pubKeyCredParams != null){
      val parameters = mutableListOf<PublicKeyCredentialParameters>() 
      for (param in pubKeyCredParams) {
        if (param is ReadableMap) {
          parameters.add( PublicKeyCredentialParameters( param.getString("type")!!, param.getInt("alg")))
        }
      }
      builder.setParameters(parameters)
    }
    return builder.build()
  }

  @ReactMethod
  fun startRegistration(creationOptionsJSON: ReadableMap, promise: Promise) {
    fido2ApiClient?.let { client ->
      try {
        val currentActivity = reactContext.getCurrentActivity() as AppCompatActivity;
        val createCredentialIntentLauncher = currentActivity.registerForActivityResult(ActivityResultContracts.StartIntentSenderForResult()) { activityResult: ActivityResult ->
          if (activityResult.resultCode != Activity.RESULT_OK){
            promise.reject(null, "User Canceled")
          } else {
            val bytes = activityResult.data?.getByteArrayExtra(Fido.FIDO2_KEY_CREDENTIAL_EXTRA);
            if (bytes == null){
              promise.reject(null, "Credential Registration Error")
            } else {
              val credential = PublicKeyCredential.deserializeFromBytes(bytes)
              val response = credential.getResponse()
              if (response is AuthenticatorErrorResponse) {
                promise.reject(null, response.errorMessage)
              } else {
                val map = Arguments.createMap()
                val rawId = credential.rawId.toBase64()
                map.putString("id", rawId)
                map.putString("rawId", rawId)
                map.putString("type", "public-key")
                val responseMap = Arguments.createMap()
                //responseMap.putString("attestationObject", response.attestationObject.toBase64())
                responseMap.putString("clientDataJSON", response.clientDataJSON.toBase64())
                map.putMap("response", responseMap)
                promise.resolve(map)
              }
            }
          }
        }
        val requestOptions = parseCreationOptions(creationOptionsJSON)
        val task = client.getRegisterPendingIntent(requestOptions)
        task.addOnSuccessListener {
          if (it != null) {
            createCredentialIntentLauncher.launch(
              IntentSenderRequest.Builder(it).build()
            )
          }
        }
      }catch (e: Exception) {
        promise.reject(null, e)
      }
    }
  }

  companion object {
    const val NAME = "AmwalAuthReactNative"
  }
}
