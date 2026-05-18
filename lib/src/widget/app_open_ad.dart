import 'package:flutter_ads_plus/flutter_ads_plus.dart';

import 'base_full_screen_ad_runner.dart';

/// One-shot helper to load + show an app-open ad. The auto-resume case
/// is handled by [AppLifecycleReactor]; this class is the direct
/// counterpart for manual shows.
///
/// Helper 1-lần để load + show app-open ad. Trường hợp auto-resume do
/// [AppLifecycleReactor] xử lý; class này là phía manual show tương
/// ứng.
class MyAppOpenAd extends BaseFullScreenAdRunner<AppOpenAdController> {
  MyAppOpenAd({
    super.adId,
    required super.context,
    super.adKey,
    super.onShowed,
    super.onFailed,
    super.adDismissed,
    this.controller,
    super.immersiveModeEnabled,
    super.showLoading,
  });

  final AppOpenAdController? controller;

  @override
  AppOpenAdController? get providedController => controller;

  @override
  AppOpenAdController buildController() => AppOpenAdController(
        adId: adId!,
        adKey: adKey,
      );
}
