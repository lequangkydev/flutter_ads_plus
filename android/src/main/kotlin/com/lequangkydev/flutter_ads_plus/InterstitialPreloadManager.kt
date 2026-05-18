package com.lequangkydev.flutter_ads_plus

import android.app.Activity
import com.google.android.gms.ads.FullScreenContentCallback
import com.google.android.gms.ads.OnPaidEventListener
import com.google.android.gms.ads.interstitial.InterstitialAd
import com.google.android.gms.ads.interstitial.InterstitialAdPreloader
import com.google.android.gms.ads.preload.PreloadCallbackV2
import com.google.android.gms.ads.preload.PreloadConfiguration
import io.flutter.plugin.common.BinaryMessenger

class InterstitialPreloadManager(
    activity: Activity,
    messenger: BinaryMessenger,
) : BaseAdPreloadManager<InterstitialAd>(
    activity = activity,
    messenger = messenger,
    channelName = "com.app.interstitial/preload",
    tagLog = "InterPreloadManager"
) {

    override fun startSdkPreload(
        adUnitId: String,
        configuration: PreloadConfiguration,
        callback: PreloadCallbackV2
    ) {
        InterstitialAdPreloader.start(adUnitId, configuration, callback)
    }

    override fun checkIsAdAvailable(adUnitId: String): Boolean {
        return InterstitialAdPreloader.isAdAvailable(adUnitId)
    }

    override fun pollSdkAd(adUnitId: String): InterstitialAd? {
        return InterstitialAdPreloader.pollAd(adUnitId)
    }

    override fun destroyAd(adUnitId: String) {
        InterstitialAdPreloader.destroy(adUnitId)
    }

    override fun destroyAllAds() {
        InterstitialAdPreloader.destroyAll()
    }

    override fun attachCallbacksAndShow(
        ad: InterstitialAd,
        paidListener: OnPaidEventListener,
        fullScreenCallback: FullScreenContentCallback
    ) {
        ad.onPaidEventListener = paidListener
        ad.fullScreenContentCallback = fullScreenCallback
        ad.show(activity)
    }
}