import '../../flutter_ads_plus.dart';

/// Controller for AdMob App-Open ads. Typically driven by
/// [AppLifecycleReactor] for the auto-resume case; direct usage via
/// [MyAds.showAppOpenAd] is also supported (e.g. splash variants).
///
/// Controller cho App-Open AdMob. Thường được [AppLifecycleReactor] điều
/// khiển cho case auto-resume; cũng có thể dùng trực tiếp qua
/// [MyAds.showAppOpenAd] (vd. cho splash variant).
class AppOpenAdController extends BaseFullScreenAdController<AppOpenAd> {
  AppOpenAdController({
    required super.adId,
    super.adKey,
  }) : super(type: AdType.appOpen);

  @override
  void loadSdkAd({
    required String adUnitId,
    required void Function(AppOpenAd ad) onAdLoaded,
    required void Function(LoadAdError error) onAdFailedToLoad,
  }) {
    AppOpenAd.load(
      adUnitId: adUnitId,
      request: MyAds.instance.adRequest,
      adLoadCallback: AppOpenAdLoadCallback(
        onAdLoaded: onAdLoaded,
        onAdFailedToLoad: onAdFailedToLoad,
      ),
    );
  }

  @override
  void attachFullScreenCallbacks(AppOpenAd ad) {
    ad.fullScreenContentCallback = buildStandardCallback<AppOpenAd>();
  }

  @override
  Future<void> doShow(AppOpenAd ad) async {
    await ad.show();
  }
}
