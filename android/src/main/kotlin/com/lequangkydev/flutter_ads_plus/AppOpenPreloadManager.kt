package com.lequangkydev.flutter_ads_plus

import android.app.Activity
import com.google.android.gms.ads.FullScreenContentCallback
import com.google.android.gms.ads.OnPaidEventListener
import com.google.android.gms.ads.appopen.AppOpenAd
import com.google.android.gms.ads.appopen.AppOpenAdPreloader
import com.google.android.gms.ads.preload.PreloadCallbackV2
import com.google.android.gms.ads.preload.PreloadConfiguration
import io.flutter.plugin.common.BinaryMessenger

class AppOpenPreloadManager(
    activity: Activity,
    messenger: BinaryMessenger,
) : BaseAdPreloadManager<AppOpenAd>(
    activity = activity,
    messenger = messenger,
    channelName = "com.app.appopen/preload",
    tagLog = "AppOpenPreloadManager"
) {

    override fun startSdkPreload(
        adUnitId: String,
        configuration: PreloadConfiguration,
        callback: PreloadCallbackV2
    ) {
        AppOpenAdPreloader.start(adUnitId, configuration, callback)
    }

    override fun checkIsAdAvailable(adUnitId: String): Boolean {
        return AppOpenAdPreloader.isAdAvailable(adUnitId)
    }

    override fun pollSdkAd(adUnitId: String): AppOpenAd? {
        return AppOpenAdPreloader.pollAd(adUnitId)
    }

    override fun destroyAd(adUnitId: String) {
        AppOpenAdPreloader.destroy(adUnitId)
    }

    override fun destroyAllAds() {
        AppOpenAdPreloader.destroyAll()
    }

    override fun attachCallbacksAndShow(
        ad: AppOpenAd,
        paidListener: OnPaidEventListener,
        fullScreenCallback: FullScreenContentCallback
    ) {
        ad.onPaidEventListener = paidListener
        ad.fullScreenContentCallback = fullScreenCallback
        ad.show(activity)
    }
}