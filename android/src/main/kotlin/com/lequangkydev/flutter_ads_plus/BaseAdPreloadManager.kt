package com.lequangkydev.flutter_ads_plus

import android.app.Activity
import android.util.Log
import com.google.android.gms.ads.AdError
import com.google.android.gms.ads.AdRequest
import com.google.android.gms.ads.FullScreenContentCallback
import com.google.android.gms.ads.OnPaidEventListener
import com.google.android.gms.ads.ResponseInfo
import com.google.android.gms.ads.preload.PreloadCallbackV2
import com.google.android.gms.ads.preload.PreloadConfiguration
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

abstract class BaseAdPreloadManager<T>(
    protected val activity: Activity,
    messenger: BinaryMessenger,
    channelName: String,
    private val tagLog: String
) : MethodChannel.MethodCallHandler {

    protected val channel = MethodChannel(messenger, channelName)

    init {
        channel.setMethodCallHandler(this)
    }

    private val preloadCallback = object : PreloadCallbackV2() {
        override fun onAdPreloaded(preloadId: String, responseInfo: ResponseInfo?) {
            Log.d(tagLog, "onAdPreloaded: $preloadId")
            channel.invokeMethod(
                "onAdPreloaded",
                mapOf(
                    "adUnitId" to preloadId,
                    "responseInfo" to (responseInfo?.toString() ?: ""),
                ),
            )
        }

        override fun onAdsExhausted(preloadId: String) {
            Log.d(tagLog, "onAdsExhausted: $preloadId")
            channel.invokeMethod(
                "onAdsExhausted",
                mapOf("adUnitId" to preloadId),
            )
        }

        override fun onAdFailedToPreload(preloadId: String, adError: AdError) {
            Log.e(tagLog, "onAdFailedToPreload: $preloadId, error=$adError")
            channel.invokeMethod(
                "onAdFailedToPreload",
                mapOf(
                    "adUnitId" to preloadId,
                    "code" to adError.code,
                    "message" to adError.message,
                    "domain" to adError.domain,
                ),
            )
        }
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "startPreload" -> {
                val adUnitId = call.argument<String>("adUnitId")
                val bufSize = call.argument<Int>("bufferSize") ?: 1
                if (adUnitId.isNullOrEmpty()) {
                    result.error("INVALID_AD_UNIT", "adUnitId is null or empty", null)
                    return
                }
                startPreloadInternal(adUnitId, bufSize)
                result.success(null)
            }

            "show" -> {
                val adUnitId = call.argument<String>("adUnitId")
                if (adUnitId.isNullOrEmpty()) {
                    result.error("INVALID_AD_UNIT", "adUnitId is null or empty", null)
                    return
                }
                showPreloadedAdInternal(adUnitId, result)
            }

            "isAdAvailable" -> {
                val adUnitId = call.argument<String>("adUnitId")
                if (adUnitId.isNullOrEmpty()) {
                    result.success(false)
                } else {
                    result.success(checkIsAdAvailable(adUnitId))
                }
            }

            "destroy" -> {
                val adUnitId = call.argument<String>("adUnitId")
                if (!adUnitId.isNullOrEmpty()) {
                    destroyAd(adUnitId)
                }
                result.success(null)
            }

            "destroyAll" -> {
                destroyAllAds()
                result.success(null)
            }

            else -> result.notImplemented()
        }
    }

    private fun startPreloadInternal(adUnitId: String, buf: Int) {
        val request = AdRequest.Builder().build()
        val configuration = PreloadConfiguration.Builder(adUnitId)
            .setAdRequest(request)
            .setBufferSize(buf)
            .build()

        startSdkPreload(adUnitId, configuration, preloadCallback)
    }

    private fun showPreloadedAdInternal(adUnitId: String, result: MethodChannel.Result) {
        if (!checkIsAdAvailable(adUnitId)) {
            result.success(false)
            return
        }
        val ad: T? = pollSdkAd(adUnitId)
        if (ad == null) {
            result.success(false)
            return
        }

        val paidListener = OnPaidEventListener { adValue ->
            channel.invokeMethod(
                "onPaidEvent",
                mapOf(
                    "adUnitId" to adUnitId,
                    "valueMicros" to adValue.valueMicros,
                    "currencyCode" to adValue.currencyCode,
                    "precisionType" to adValue.precisionType,
                ),
            )
        }

        val fullScreenCallback = object : FullScreenContentCallback() {
            override fun onAdShowedFullScreenContent() {
                channel.invokeMethod("onAdShowed", mapOf("adUnitId" to adUnitId))
            }

            override fun onAdDismissedFullScreenContent() {
                channel.invokeMethod("onAdDismissed", mapOf("adUnitId" to adUnitId))
            }

            override fun onAdFailedToShowFullScreenContent(adError: AdError) {
                channel.invokeMethod(
                    "onAdFailedToShow",
                    mapOf(
                        "adUnitId" to adUnitId,
                        "code" to adError.code,
                        "message" to adError.message,
                        "domain" to adError.domain,
                    ),
                )
            }
        }

        attachCallbacksAndShow(ad, paidListener, fullScreenCallback)
        result.success(true)
    }

    // --- Abstract delegates cho các class con tự implement ---
    abstract fun startSdkPreload(
        adUnitId: String,
        configuration: PreloadConfiguration,
        callback: PreloadCallbackV2
    )

    abstract fun checkIsAdAvailable(adUnitId: String): Boolean
    abstract fun pollSdkAd(adUnitId: String): T?
    abstract fun destroyAd(adUnitId: String)
    abstract fun destroyAllAds()
    abstract fun attachCallbacksAndShow(
        ad: T,
        paidListener: OnPaidEventListener,
        fullScreenCallback: FullScreenContentCallback
    )
}