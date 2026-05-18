package com.lequangkydev.flutter_ads_plus_example

import android.content.Context
import android.view.LayoutInflater
import android.view.View
import android.widget.LinearLayout
import android.widget.Button
import android.widget.ImageView
import android.widget.TextView
import com.google.android.gms.ads.nativead.MediaView
import com.google.android.gms.ads.nativead.NativeAd
import com.google.android.gms.ads.nativead.NativeAdView
import io.flutter.plugins.googlemobileads.GoogleMobileAdsPlugin.NativeAdFactory


class HomeNativeAd(
    private val context: Context,
) :
    NativeAdFactory {
    override fun createNativeAd(
        nativeAd: NativeAd,
        customOptions: MutableMap<String, Any>?
    ): NativeAdView {
        val adLayout = R.layout.home_native_ad;
        val adView =
            LayoutInflater.from(context).inflate(adLayout, null) as NativeAdView

        with(adView) {
            val headlineView = findViewById<TextView>(R.id.ad_headline)
            setHeadlineView(headlineView)
            val bodyView = findViewById<TextView>(R.id.ad_body)
            setBodyView(bodyView)
            val callToActionView = findViewById<Button>(R.id.ad_call_to_action)
            setCallToActionView(callToActionView)
            val iconView = findViewById<ImageView>(R.id.ad_app_icon)
            setIconView(iconView)
            val adTextView = findViewById<TextView>(R.id.ad)
            advertiserView = adTextView
            headlineView.text = nativeAd.headline

            val mediaView = findViewById<MediaView>(R.id.ad_media)

            setMediaView(mediaView)
            mediaView.mediaContent = nativeAd.mediaContent


            if (nativeAd.body == null) {
                bodyView.visibility = View.INVISIBLE
            } else {
                bodyView.text = nativeAd.body
            }
            if (nativeAd.callToAction == null) {
                callToActionView.visibility = View.INVISIBLE
            } else {
                callToActionView.text = nativeAd.callToAction
            }
            if (nativeAd.icon == null) {
                iconView.apply {
                    visibility = View.INVISIBLE
                    layoutParams = LinearLayout.LayoutParams(16, 16)
                }
            } else {
                iconView.setImageDrawable(nativeAd.icon!!.drawable)
            }
            setNativeAd(nativeAd)
        }
        return adView
    }
}
