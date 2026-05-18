package com.lequangkydev.flutter_ads_plus

import androidx.annotation.NonNull
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.BinaryMessenger

/** FlutterAdsPlugin */
class FlutterAdsPlugin : FlutterPlugin, ActivityAware {

    /// Lưu lại BinaryMessenger từ onAttachedToEngine để dùng trong onAttachedToActivity.
    private lateinit var messenger: BinaryMessenger

    private var interstitialPreloadManager: InterstitialPreloadManager? = null
    private var appOpenPreloadManager: AppOpenPreloadManager? = null

    override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        messenger = flutterPluginBinding.binaryMessenger
    }

    override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        // nothing to clean up
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        interstitialPreloadManager = InterstitialPreloadManager(binding.activity, messenger)
        appOpenPreloadManager = AppOpenPreloadManager(binding.activity, messenger)
    }

    override fun onDetachedFromActivityForConfigChanges() {
        // Null ra để release Activity cũ trước khi Activity mới gắn vào
        interstitialPreloadManager = null
        appOpenPreloadManager = null
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        // Tạo lại manager với Activity mới (sau xoay màn hình v.v.)
        // InterstitialAdPreloader / AppOpenAdPreloader là static → buffer ads vẫn còn
        interstitialPreloadManager = InterstitialPreloadManager(binding.activity, messenger)
        appOpenPreloadManager = AppOpenPreloadManager(binding.activity, messenger)
    }

    override fun onDetachedFromActivity() {
        interstitialPreloadManager = null
        appOpenPreloadManager = null
    }
}
