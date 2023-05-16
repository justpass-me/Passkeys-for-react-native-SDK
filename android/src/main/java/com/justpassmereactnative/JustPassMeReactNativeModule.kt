package com.JustPassMeReactNative

import com.facebook.react.bridge.Arguments
import com.facebook.react.bridge.Promise
import com.facebook.react.bridge.ReactApplicationContext
import com.facebook.react.bridge.ReactContextBaseJavaModule
import com.facebook.react.bridge.ReactMethod
import com.facebook.react.bridge.ReadableMap
import tech.amwal.justpassme.AuthResponse
import tech.amwal.justpassme.JustPassMe

class JustPassMeReactNativeModule(reactContext: ReactApplicationContext) :
  ReactContextBaseJavaModule(reactContext) {

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
    extraClientHeaders: ReadableMap?,
    promise: Promise
  ) {
    currentActivity?.let {
      JustPassMe(activity = it)
    }?.register(
      registrationURL,
      extraClientHeaders?.toHashMap() as? Map<String, String>? ?: emptyMap()
    ) {
      when (it) {
        is AuthResponse.Success -> promise.resolve(Arguments.createMap().apply {
          putString("token", it.token)
        })

        is AuthResponse.Error -> promise.reject(it.error, it.error)
      }
    }
  }


  @ReactMethod
  fun startAuthentication(
    authenticationURL: String,
    extraClientHeaders: ReadableMap?,
    promise: Promise
  ) {
    currentActivity?.let {
      JustPassMe(activity = it)
    }?.auth(
      authenticationURL,
      extraClientHeaders?.toHashMap() as? Map<String, String>? ?: emptyMap()
    ) {
      when (it) {
        is AuthResponse.Success -> promise.resolve(Arguments.createMap().apply {
          putString("token", it.token)
        })

        is AuthResponse.Error -> promise.reject(it.error, it.error)
      }
    }

  }

}
