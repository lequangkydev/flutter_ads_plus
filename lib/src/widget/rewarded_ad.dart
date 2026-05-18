import 'package:flutter_ads_plus/flutter_ads_plus.dart';

import 'base_full_screen_ad_runner.dart';

/// One-shot helper to load + show a rewarded ad. Wire
/// [onUserEarnedReward] to grant the reward.
///
/// Helper 1-lần để load + show reward ad. Nối [onUserEarnedReward] để
/// cấp reward.
class MyRewardedAd extends BaseFullScreenAdRunner<RewardedAdController> {
  MyRewardedAd({
    required super.adId,
    required super.context,
    super.onShowed,
    super.adDismissed,
    super.onFailed,
    this.onUserEarnedReward,
    super.adKey,
    this.controller,
    super.immersiveModeEnabled,
    super.showLoading,
  });

  final void Function()? onUserEarnedReward;
  final RewardedAdController? controller;

  @override
  RewardedAdController? get providedController => controller;

  @override
  RewardedAdController buildController() => RewardedAdController(
        adId: adId!,
        adKey: adKey,
      );

  @override
  void attachExtraCallbacks(RewardedAdController controller) {
    controller.onUserEarnedReward = (ad, reward) => onUserEarnedReward?.call();
  }
}
