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
import io.flutter.plugins.googlemobileads.GoogleMobileAdsPlugin

class ExtraNativeAd(
    private val context: Context,
    private val buttonPosition: ButtonPosition = ButtonPosition.Bottom,
) :
    GoogleMobileAdsPlugin.NativeAdFactory {
    override fun createNativeAd(
        nativeAd: NativeAd,
        customOptions: MutableMap<String, Any>?
    ): NativeAdView {
        val adView =
            LayoutInflater.from(context)
                .inflate(R.layout.custom_extra_native_ad, null) as NativeAdView

        with(adView) {
            // Set the media view.
            val mediaView = findViewById<MediaView>(R.id.ad_media)
            setMediaView(mediaView)

            // Set other ad assets.
            val headlineView = findViewById<TextView>(R.id.ad_headline)
            setHeadlineView(headlineView)
            val bodyView = findViewById<TextView>(R.id.ad_body)
            setBodyView(bodyView)
            val buttonId: Int;
            if (buttonPosition == ButtonPosition.Bottom) {
                buttonId = R.id.ad_call_to_action_bottom;
                findViewById<Button>(R.id.ad_call_to_action).visibility = View.GONE
            } else {
                buttonId = R.id.ad_call_to_action;
                findViewById<Button>(R.id.ad_call_to_action_bottom).visibility = View.GONE
            }
            val callToActionView = findViewById<Button>(buttonId)
            setCallToActionView(callToActionView)
            val iconView = findViewById<ImageView>(R.id.ad_app_icon)
            setIconView(iconView)

            // The headline and mediaContent are guaranteed to be in every NativeAd.
            headlineView.text = nativeAd.headline
            advertiserView = findViewById<TextView>(R.id.adText)

            mediaView.mediaContent = nativeAd.mediaContent

            // These assets aren't guaranteed to be in every NativeAd, so it's important to
            // check before trying to display them.
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