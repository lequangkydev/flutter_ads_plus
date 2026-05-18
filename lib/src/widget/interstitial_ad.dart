import 'package:flutter_ads_plus/flutter_ads_plus.dart';

import 'base_full_screen_ad_runner.dart';

/// One-shot helper to load + show an interstitial ad with the standard
/// lifecycle + loading overlay. Prefer [MyAds.showInterstitialAd] when
/// you also want the global interval throttle and preload-first
/// behavior; use this directly when you've already got a controller and
/// want a thin runner.
///
/// Helper 1-lần để load + show inter ad với lifecycle + loading overlay
/// chuẩn. Ưu tiên [MyAds.showInterstitialAd] nếu muốn cả throttle global
/// và preload-first; dùng class này trực tiếp khi đã có controller và
/// chỉ cần runner mỏng.
class MyInterstitialAd extends BaseFullScreenAdRunner<InterstitialAdController> {
  MyInterstitialAd({
    super.adId,
    required super.context,
    super.onShowed,
    super.adDismissed,
    super.onFailed,
    this.onAdClicked,
    super.showLoading,
    this.controller,
    super.adKey,
    super.immersiveModeEnabled,
  });

  final void Function()? onAdClicked;
  final InterstitialAdController? controller;

  @override
  InterstitialAdController? get providedController => controller;

  @override
  InterstitialAdController buildController() => InterstitialAdController(
        adId: adId!,
        adKey: adKey,
      );

  @override
  void attachExtraCallbacks(InterstitialAdController controller) {
    controller.onAdClicked = (ad) => onAdClicked?.call();
  }
}
