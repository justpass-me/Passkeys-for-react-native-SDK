package com.amwalauthreactnative

import androidx.activity.ComponentActivity
import androidx.lifecycle.lifecycleScope
import com.facebook.react.bridge.Promise
import com.facebook.react.bridge.ReactApplicationContext
import com.facebook.react.bridge.ReactContextBaseJavaModule
import com.facebook.react.bridge.ReactMethod
import com.facebook.react.modules.network.OkHttpClientProvider
import com.facebook.react.modules.network.ReactCookieJarContainer
import kotlinx.coroutines.launch
import tech.amwal.auth.android.AndroidAuth

class AmwalAuthReactNativeModule(private val reactContext: ReactApplicationContext) :
  ReactContextBaseJavaModule(reactContext) {

  override fun getName(): String {
    return NAME
  }

  override fun getConstants() = mapOf(
    "isAvailable" to true
  )

  @ReactMethod
  fun startRegistration(
    clientURL: String,
    authServiceURL: String,
    promise: Promise
  ) {

    reactContext.currentActivity?.let {
      AndroidAuth(
        clientUrl = clientURL,
        serviceUrl = authServiceURL,
        activity = it,
        httpClient = OkHttpClientProvider.getOkHttpClient()
      ).apply {
        (it as ComponentActivity).lifecycleScope.launch {
          try {
            register()
            promise.resolve(Unit)
          } catch (e: Exception) {
            e.printStackTrace()
            promise.reject(e)
          }
        }
      }
    }
  }

  companion object {
    const val NAME = "AmwalAuthReactNative"
  }

  @ReactMethod
  fun startAuthentication(
    clientURL: String,
    authServiceURL: String,
    autoFill: Boolean,
    promise: Promise
  ) {
    reactContext.currentActivity?.let {
      AndroidAuth(
        clientUrl = clientURL,
        serviceUrl = authServiceURL,
        activity = it,
        httpClient = OkHttpClientProvider.getOkHttpClient()
      ).apply {
        (it as ComponentActivity).lifecycleScope.launch {
          try {
            auth()
            promise.resolve(Unit)
          } catch (e: Exception) {
            e.printStackTrace()
            promise.reject(e)
          }
        }
      }
    }
  }

}
