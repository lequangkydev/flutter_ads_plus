package com.lequangkydev.flutter_ads_plus_example

import android.os.Bundle
import androidx.core.view.WindowCompat
import androidx.core.view.WindowInsetsControllerCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugins.googlemobileads.GoogleMobileAdsPlugin

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        val windowInsetsController =
            WindowCompat.getInsetsController(window, window.decorView)
        windowInsetsController?.systemBarsBehavior =
            WindowInsetsControllerCompat.BEHAVIOR_SHOW_BARS_BY_SWIPE
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        GoogleMobileAdsPlugin.registerNativeAdFactory(
            flutterEngine,
            "topExtraNativeAd",
            ExtraNativeAd(context, buttonPosition = ButtonPosition.Top)
        )
        GoogleMobileAdsPlugin.registerNativeAdFactory(
            flutterEngine,
            "bottomExtraNativeAd",
            ExtraNativeAd(context, buttonPosition = ButtonPosition.Bottom)
        )
        GoogleMobileAdsPlugin.registerNativeAdFactory(
            flutterEngine,
            "topNormalNativeAd",
            NormalNativeAd(context, buttonPosition = ButtonPosition.Top)
        )
        GoogleMobileAdsPlugin.registerNativeAdFactory(
            flutterEngine,
            "bottomNormalNativeAd",
            NormalNativeAd(context, buttonPosition = ButtonPosition.Bottom)
        )
        GoogleMobileAdsPlugin.registerNativeAdFactory(
            flutterEngine,
            "homeNativeAd",
            HomeNativeAd(context)
        )
        GoogleMobileAdsPlugin.registerNativeAdFactory(
            flutterEngine,
            "smallNativeAd",
            SmallNativeAd(context)
        )
        GoogleMobileAdsPlugin.registerNativeAdFactory(
            flutterEngine,
            "fullNativeAd",
            FullNativeAd(context)
        )
    }

    override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
        super.cleanUpFlutterEngine(flutterEngine)

        GoogleMobileAdsPlugin.unregisterNativeAdFactory(flutterEngine, "topExtraNativeAd")
        GoogleMobileAdsPlugin.unregisterNativeAdFactory(flutterEngine, "bottomExtraNativeAd")
        GoogleMobileAdsPlugin.unregisterNativeAdFactory(flutterEngine, "topNormalNativeAd")
        GoogleMobileAdsPlugin.unregisterNativeAdFactory(flutterEngine, "bottomNormalNativeAd")
        GoogleMobileAdsPlugin.unregisterNativeAdFactory(flutterEngine, "homeNativeAd")
        GoogleMobileAdsPlugin.unregisterNativeAdFactory(flutterEngine, "smallNativeAd")
        GoogleMobileAdsPlugin.unregisterNativeAdFactory(flutterEngine, "fullNativeAd")
    }
}
