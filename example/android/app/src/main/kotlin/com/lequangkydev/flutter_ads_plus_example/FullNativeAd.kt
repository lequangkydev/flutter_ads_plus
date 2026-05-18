package com.lequangkydev.flutter_ads_plus_example

import android.content.Context
import android.view.LayoutInflater
import android.view.View
import android.widget.Button
import android.widget.ImageView
import android.widget.TextView
import androidx.core.content.ContextCompat
import com.google.android.gms.ads.nativead.MediaView
import com.google.android.gms.ads.nativead.NativeAd
import com.google.android.gms.ads.nativead.NativeAdView
import io.flutter.plugins.googlemobileads.GoogleMobileAdsPlugin.NativeAdFactory


class FullNativeAd(
    private val context: Context,
) :
    NativeAdFactory {
    override fun createNativeAd(
        nativeAd: NativeAd,
        customOptions: MutableMap<String, Any>?
    ): NativeAdView {
        val adView =
            LayoutInflater.from(context).inflate(R.layout.full_native_ad, null) as NativeAdView

        with(adView) {
            val headlineView = findViewById<TextView>(R.id.ad_headline)
            setHeadlineView(headlineView)
            val bodyView = findViewById<TextView>(R.id.ad_body)
            setBodyView(bodyView)
            val callToActionView = findViewById<Button>(R.id.bottom_ad_call_to_action)
            setCallToActionView(callToActionView)
            headlineView.text = nativeAd.headline

            val mediaView = findViewById<MediaView>(R.id.ad_media)
            setMediaView(mediaView)
            mediaView.mediaContent = nativeAd.mediaContent

            if (nativeAd.body == null) {
                bodyView.visibility = View.INVISIBLE
            } else {
                bodyView.visibility = View.VISIBLE
                bodyView.text = nativeAd.body
            }
            if (nativeAd.callToAction == null) {
                callToActionView.visibility = View.INVISIBLE
            } else {
                callToActionView.visibility = View.VISIBLE
                callToActionView.text = nativeAd.callToAction
            }


            setNativeAd(nativeAd)
        }
        return adView
    }
}
