package com.JustPassMeReactNative

import com.facebook.react.bridge.Promise
import com.facebook.react.bridge.ReactApplicationContext
import com.facebook.react.bridge.ReactContextBaseJavaModule
import com.facebook.react.bridge.ReactMethod
import tech.amwal.justpassme.AuthResponse
import tech.amwal.justpassme.JustPassMe

class JustPassMeReactNativeModule(reactContext: ReactApplicationContext) :
  ReactContextBaseJavaModule(reactContext) {
  private val justPassMe = JustPassMe(reactContext.applicationContext)

  override fun getName(): String {
    return NAME
  }

  override fun getConstants() = mapOf(
    "isAvailable" to true
  )

  companion object {
    const val NAME = "JustPassMeReactNative"
  }

  @ReactMethod
  fun startRegistration(
    registrationURL: String,
    extraClientHeaders: Map<String, String>,
    promise: Promise
  ) {
    justPassMe.register(registrationURL, extraClientHeaders) {
      when (it) {
        is AuthResponse.Success -> promise.resolve(it)

        is AuthResponse.Error -> promise.reject(it.error, it.error)
      }
    }
  }


  @ReactMethod
  fun startAuthentication(
    authenticationURL: String,
    extraClientHeaders: Map<String, String>,
    promise: Promise
  ) {
    justPassMe.auth(authenticationURL, extraClientHeaders) {
      when (it) {
        is AuthResponse.Success -> promise.resolve(it)

        is AuthResponse.Error -> promise.reject(it.error, it.error)
      }
    }

  }

}
