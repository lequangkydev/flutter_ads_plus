import '../../flutter_ads_plus.dart';

/// Controller for AdMob Rewarded ads. Show via [MyAds.showRewardAd] or
/// [MyRewardedAd] runner; subscribe to [onUserEarnedReward] to grant
/// the reward in your app code.
///
/// Controller cho Rewarded AdMob. Show qua [MyAds.showRewardAd] hoặc
/// runner [MyRewardedAd]; subscribe [onUserEarnedReward] để cấp reward
/// trong app code.
class RewardedAdController extends BaseFullScreenAdController<RewardedAd> {
  RewardedAdController({
    required super.adId,
    super.adKey,
  }) : super(type: AdType.reward);

  /// Fired when the SDK confirms the user has earned the reward. Wire
  /// to your reward grant logic.
  ///
  /// Fire khi SDK xác nhận user đã earn reward. Nối vào logic cấp reward
  /// của app.
  OnUserEarnedRewardCallback? onUserEarnedReward;

  @override
  void loadSdkAd({
    required String adUnitId,
    required void Function(RewardedAd ad) onAdLoaded,
    required void Function(LoadAdError error) onAdFailedToLoad,
  }) {
    RewardedAd.load(
      adUnitId: adUnitId,
      request: MyAds.instance.adRequest,
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: onAdLoaded,
        onAdFailedToLoad: onAdFailedToLoad,
      ),
    );
  }

  @override
  void attachFullScreenCallbacks(RewardedAd ad) {
    ad.fullScreenContentCallback = buildStandardCallback<RewardedAd>();
  }

  @override
  Future<void> doShow(RewardedAd ad) async {
    await ad.show(onUserEarnedReward: (rewardAd, reward) {
      addEvent(status: AdStatus.earnReward, adId: ad.adUnitId);
      onUserEarnedReward?.call(rewardAd, reward);
    });
  }
}
