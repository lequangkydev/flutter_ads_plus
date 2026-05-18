import 'dart:async';

import '../../flutter_ads_plus.dart';
import '../utils/my_completer.dart';

/// Controller for AdMob Native ads. Pair with [MyNativeAd] /
/// [MyNativeAd2] to render via the registered native ad factory
/// ([factoryId] on the native side).
///
/// Controller cho Native AdMob. Ghép với [MyNativeAd] / [MyNativeAd2] để
/// render qua native ad factory đã đăng ký ([factoryId] phía native).
class NativeAdController extends AdController {
  NativeAdController({
    required super.adId,
    required this.factoryId,
    this.loadOnImpression = false,
    this.reloadOnClicked,
    super.type = AdType.native,
    this.nativeAdOptions,
    this.customOptions,
    super.adKey,
  });

  /// Native ad factory id registered on the platform side (Android /
  /// iOS) — must match an entry registered with the Google Mobile Ads
  /// plugin.
  ///
  /// Native ad factory id đăng ký phía platform (Android / iOS) — phải
  /// trùng với entry đã register với plugin Google Mobile Ads.
  final String factoryId;

  /// Start loading a *second* native ad as soon as the *first* one
  /// reports impression. Use together with [MyNativeAd2] +
  /// [updateAd] to swap the new ad in without a visible gap.
  ///
  /// Bắt đầu load 1 native ad *thứ 2* ngay khi ad thứ nhất báo
  /// impression. Dùng kèm [MyNativeAd2] + [updateAd] để swap ad mới vào
  /// mà không có gap nhìn thấy được.
  final bool loadOnImpression;

  /// Per-controller override of [MyAds.reloadNativeAdWhenClicked]. When
  /// `null`, follows the global default.
  ///
  /// Override [MyAds.reloadNativeAdWhenClicked] cho controller này. Nếu
  /// `null`, theo mặc định global.
  final bool? reloadOnClicked;

  final NativeAdOptions? nativeAdOptions;
  final Map<String, Object>? customOptions;
  AdEventCallback? onAdOpened;
  AdEventCallback? onAdClosed;
  NativeAd? _nativeAd;

  /// Background-loaded ad ready to swap in via [updateAd]. Populated
  /// by [loadOnImpression] flow.
  ///
  /// Ad load sẵn background, sẵn sàng swap qua [updateAd]. Được fill
  /// bởi flow [loadOnImpression].
  NativeAd? _preloadedNativeAd;
  final String controllerId = DateTime.now().microsecondsSinceEpoch.toString();

  LoadAdError? _error;

  /// `true` after the impression-triggered second load fires. Read by
  /// [MyNativeAd2] to keep showing the current ad until [updateAd] is
  /// called.
  ///
  /// `true` sau khi load thứ 2 (trigger bởi impression) fire. Đọc bởi
  /// [MyNativeAd2] để vẫn show ad hiện tại cho đến khi [updateAd] gọi.
  bool loadSecondAd = false;

  NativeAd? get ad => _nativeAd;

  bool isImpression = false;

  /// Swap the preloaded ad into [ad] and dispose the previous one.
  /// Call from your UI after the next render boundary (e.g. on a timer
  /// or page transition) to refresh without a flash.
  ///
  /// Swap ad đã preload thành [ad] và dispose ad cũ. Gọi từ UI sau ranh
  /// giới render (vd. timer hoặc page transition) để refresh không bị
  /// flash.
  Future<void> updateAd() async {
    if (_preloadedNativeAd == null) {
      return;
    }
    isImpression = false;
    _nativeAd?.dispose();
    _nativeAd = _preloadedNativeAd;
    _preloadedNativeAd = null;
    addEvent(status: AdStatus.shown, adId: _nativeAd!.adUnitId);
  }

  @override
  Future<void> load() async {
    _nativeAd = await _loadAd(id: adId);
    if (_nativeAd == null) {
      addEvent(status: AdStatus.loadFailed, adId: adId);
      onAdFailedToLoad?.call(
          null, _error ?? LoadAdError(0, '', 'Id is empty', null));
    } else {
      onLoaded?.call(_nativeAd!);
      addEvent(status: AdStatus.loaded, adId: _nativeAd!.adUnitId);
    }
  }

  Future<NativeAd?> _loadAd({required String id}) async {
    if (id.isEmpty) {
      return null;
    }
    if (status.isLoading || status.isLoaded || !MyAds.instance.hasInternet) {
      return _nativeAd;
    }
    addEvent(status: AdStatus.loading, adId: id);
    MyCompleter<NativeAd?> completer = MyCompleter();
    final nativeAd = NativeAd(
      adUnitId: id,
      factoryId: factoryId,
      request: MyAds.instance.adRequest,
      nativeAdOptions: nativeAdOptions ??
          NativeAdOptions(
            adChoicesPlacement: AdChoicesPlacement.bottomRightCorner,
          ),
      customOptions: customOptions,
      listener: NativeAdListener(
        onAdLoaded: (ad) {
          completer.complete(ad as NativeAd);
        },
        onAdClicked: (ad) {
          addEvent(status: AdStatus.clicked, adId: id);
          onAdClicked?.call(ad);
          if (reloadOnClicked ?? MyAds.instance.reloadNativeAdWhenClicked) {
            _nativeAd = null;
            reload();
          }
        },
        onAdClosed: (ad) {
          addEvent(status: AdStatus.closed, adId: id);
          onAdClosed?.call(ad);
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
        onAdWillDismissScreen: (ad) {
          addEvent(status: AdStatus.dismiss, adId: id);
          onDismissed?.call(ad);
        },
        onAdFailedToLoad: (Ad ad, LoadAdError error) async {
          _error = error;
          ad.dispose();
          addEvent(status: AdStatus.loadFailed, error: error, adId: id);
          onAdFailedToLoad?.call(ad, error);
          completer.complete();
        },
        onAdImpression: (ad) async {
          isImpression = true;
          addEvent(status: AdStatus.impression, adId: id);
          onAdImpression?.call(ad);
          if (loadOnImpression) {
            loadSecondAd = true;
            _preloadedNativeAd = await _loadAd(id: adId);
          }
        },
      ),
    );
    nativeAd.load();
    return completer.future;
  }

  @override
  Future<void> reload() async {
    isImpression = false;
    await disposeAd();
    await load();
  }

  @override
  Future<void> disposeAd() async {
    addEvent(status: AdStatus.init, adId: _nativeAd?.adUnitId ?? adId);
    await _nativeAd?.dispose();
    _nativeAd = null;
  }

  NativeAdController copyWith({
    String? factoryId,
    String? adId,
    bool? loadOnImpression,
    String? adKey,
    Map<String, Object>? customOptions,
    bool? reloadOnClicked,
    NativeAdOptions? nativeAdOptions,
  }) {
    return NativeAdController(
      factoryId: factoryId ?? this.factoryId,
      adId: adId ?? super.adId,
      adKey: adKey ?? super.adKey,
      customOptions: customOptions ?? this.customOptions,
      reloadOnClicked: reloadOnClicked ?? this.reloadOnClicked,
      nativeAdOptions: nativeAdOptions ?? this.nativeAdOptions,
      loadOnImpression: loadOnImpression ?? this.loadOnImpression,
    );
  }
}
