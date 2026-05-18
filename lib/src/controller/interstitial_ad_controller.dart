import 'package:flutter/material.dart';

import '../../flutter_ads_plus.dart';

/// Controller for AdMob Interstitial ads. Owns lifecycle; show via
/// [MyAds.showInterstitialAd] or [MyInterstitialAd] runner.
///
/// Controller cho Interstitial AdMob. Quản lý vòng đời; show qua
/// [MyAds.showInterstitialAd] hoặc runner [MyInterstitialAd].
class InterstitialAdController extends BaseFullScreenAdController<InterstitialAd> {
  InterstitialAdController({
    required super.adId,
    super.adKey,
    this.reloadOnDismiss = false,
  }) : super(type: AdType.interstitial);

  /// Auto-reload right after the ad dismisses so the next show is
  /// instant. Useful for inter-heavy flows.
  ///
  /// Auto reload ngay sau khi ad dismiss để lần show tiếp theo tức thì.
  /// Hữu ích cho flow show inter nhiều.
  final bool reloadOnDismiss;
  BuildContext? context;

  @override
  void loadSdkAd({
    required String adUnitId,
    required void Function(InterstitialAd ad) onAdLoaded,
    required void Function(LoadAdError error) onAdFailedToLoad,
  }) {
    InterstitialAd.load(
      adUnitId: adUnitId,
      request: MyAds.instance.adRequest,
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: onAdLoaded,
        onAdFailedToLoad: onAdFailedToLoad,
      ),
    );
  }

  @override
  void attachFullScreenCallbacks(InterstitialAd ad) {
    ad.fullScreenContentCallback = buildStandardCallback<InterstitialAd>(
      onDismissedExtra: (_) {
        if (reloadOnDismiss) load();
      },
    );
  }

  @override
  Future<void> doShow(InterstitialAd ad) async {
    await ad.show();
  }
}
