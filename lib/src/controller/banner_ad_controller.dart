import 'dart:async';

import '../../flutter_ads_plus.dart';
import '../utils/my_completer.dart';

/// Controller for AdMob Banner ads (standard + collapsible). Plug into
/// [MyBannerAd] or [MyBannerAd.control] to render.
///
/// Controller cho Banner AdMob (standard + collapsible). Cắm vào
/// [MyBannerAd] hoặc [MyBannerAd.control] để render.
class BannerAdController extends AdController {
  BannerAdController({
    required super.adId,
    this.adSize,
    this.isCollapsible = false,
    super.type = AdType.banner,
    super.adKey,
  });

  /// `true` makes the banner request a collapsible variant
  /// (`{'collapsible': 'bottom'}` extras). User can swipe to collapse.
  ///
  /// `true` để yêu cầu biến thể collapsible (`{'collapsible': 'bottom'}`
  /// trong extras). User có thể vuốt để thu gọn.
  final bool isCollapsible;

  /// Banner size; falls back to [MyAds.bannerAdSize] (anchored adaptive),
  /// then to [AdSize.banner] if still unset.
  ///
  /// Kích thước banner; fallback về [MyAds.bannerAdSize] (anchored
  /// adaptive), rồi [AdSize.banner] nếu vẫn null.
  AdSize? adSize;
  AdEventCallback? onAdOpened;
  AdEventCallback? onAdClosed;
  BannerAd? _ad;

  /// Identity used by [MyBannerAd.didUpdateWidget] to detect a
  /// controller swap (same controller instance ⇒ same id).
  ///
  /// Định danh dùng bởi [MyBannerAd.didUpdateWidget] để detect controller
  /// bị thay (cùng instance ⇒ cùng id).
  final String controllerId = DateTime
      .now()
      .microsecondsSinceEpoch
      .toString();

  BannerAd? get ad => _ad;
  bool isImpression = false;

  LoadAdError? _error;

  @override
  Future<void> load() async {
    _ad = await _loadAd(id: adId);
    if (_ad == null) {
      addEvent(status: AdStatus.loadFailed, adId: adId);
      onAdFailedToLoad?.call(
          null, _error ?? LoadAdError(0, '', 'Id is empty', null));
    } else {
      onLoaded?.call(_ad!);
      addEvent(status: AdStatus.loaded, adId: _ad!.adUnitId);
    }
  }

  Future<BannerAd?> _loadAd({required String id}) async {
    if (id.isEmpty) {
      return null;
    }
    if (status.isLoading || status.isLoaded || !MyAds.instance.hasInternet) {
      return _ad;
    }
    MyCompleter<BannerAd?> completer = MyCompleter();
    adSize ??= MyAds.instance.bannerAdSize ?? AdSize.banner;
    _ad = BannerAd(
      size: adSize!,
      adUnitId: id,
      listener: BannerAdListener(
        onAdLoaded: (Ad ad) {
          completer.complete(ad as BannerAd);
        },
        onAdFailedToLoad: (Ad ad, LoadAdError error) async {
          _error = error;
          ad.dispose();
          addEvent(
            status: AdStatus.loadFailed,
            error: error,
            adId: id,
          );
          onAdFailedToLoad?.call(ad, error);
          completer.complete();
        },
        onAdClicked: (ad) {
          addEvent(
            status: AdStatus.clicked,
            adId: id,
          );
          onAdClicked?.call(ad);
        },
        onAdImpression: (ad) {
          isImpression = true;
          addEvent(
            status: AdStatus.impression,
            adId: id,
          );
          onAdImpression?.call(ad);
        },
        onPaidEvent: (ad, valueMicros, precision, currencyCode) {
          addEvent(
            status: AdStatus.paid,
            adId: id,
            valueMicros: valueMicros,
            precision: precision,
            currencyCode: currencyCode,
          );
          onPaidEvent?.call(ad, valueMicros, precision, currencyCode);
        },
        onAdOpened: (ad) {
          addEvent(status: AdStatus.opened, adId: id);
          onAdOpened?.call(ad);
        },
        onAdClosed: (ad) {
          addEvent(status: AdStatus.closed, adId: id);
          onAdClosed?.call(ad);
        },
        onAdWillDismissScreen: (ad) {
          addEvent(status: AdStatus.dismiss, adId: id);
          onDismissed?.call(ad);
        },
      ),
      request: AdRequest(
        httpTimeoutMillis: MyAds.instance.adRequest.httpTimeoutMillis,
        extras: isCollapsible ? {'collapsible': 'bottom'} : null,
      ),
    );
    addEvent(status: AdStatus.loading, adId: id);
    _ad?.load();
    return completer.future;
  }

  @override
  Future<void> reload() async {
    await disposeAd();
    await load();
  }

  @override
  Future<void> disposeAd() async {
    addEvent(status: AdStatus.init, adId: _ad?.adUnitId ?? '');
    await _ad?.dispose();
    _ad = null;
  }

  BannerAdController copyWith({
    bool? isCollapsible,
    AdSize? adSize,
    String? adId,
  }) {
    return BannerAdController(
      isCollapsible: isCollapsible ?? this.isCollapsible,
      adSize: adSize ?? this.adSize,
      adId: adId ?? super.adId,
    );
  }
}
