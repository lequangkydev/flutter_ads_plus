import 'dart:async';

import '../../flutter_ads_plus.dart';
import '../utils/logger.dart';
import '../utils/my_completer.dart';

typedef AdStatusCallback = void Function(AdStatus status);

/// Base for every ad controller in this package. Owns the [status]
/// stream, the per-event callbacks, and the show-rate / event-stream
/// bookkeeping.
///
/// Lớp cơ sở cho mọi ad controller trong package. Giữ stream [status],
/// các callback theo event, và bookkeeping show-rate / event-stream.
///
/// Concrete subclasses (Banner / Native / Interstitial / Reward /
/// AppOpen) implement [load] / [disposeAd] for the SDK type they wrap.
///
/// Subclass cụ thể (Banner / Native / Interstitial / Reward / AppOpen)
/// implement [load] / [disposeAd] cho SDK type tương ứng.
abstract class AdController {
  AdController({
    required this.adId,
    required this.type,
    this.adKey,
  });

  /// AdMob ad unit id. / Ad unit id của AdMob.
  final String adId;

  /// Optional label used for the show-rate logger and event metadata.
  /// Logs / events without an [adKey] are still emitted but skipped by
  /// [updateShowRate].
  ///
  /// Nhãn tuỳ chọn cho show-rate logger và metadata của event. Event
  /// không có [adKey] vẫn được emit nhưng [updateShowRate] bỏ qua.
  final String? adKey;

  /// Ad type bucket. / Phân loại ad type.
  final AdType type;

  /// Fired when the SDK reports a successful load. / Fire khi SDK báo
  /// load thành công.
  AdEventCallback? onLoaded;

  /// Fired when the ad is dismissed (closed by user or system).
  /// Fire khi ad bị dismiss (user hoặc system đóng).
  AdEventCallback? onDismissed;

  /// Fired on the first valid impression — i.e. the SDK confirmed the
  /// ad was actually shown to the user.
  ///
  /// Fire ở impression đầu tiên hợp lệ — SDK xác nhận ad đã thực sự
  /// hiển thị tới user.
  AdEventCallback? onAdImpression;

  /// Paid event (only available on allow-listed AdMob accounts).
  /// Forward this to your analytics/attribution pipeline.
  ///
  /// Paid event (chỉ available cho AdMob account được cấp quyền). Forward
  /// về pipeline analytics / attribution.
  void Function(Ad? ad, double valueMicros, PrecisionType precision,
      String currencyCode)? onPaidEvent;

  /// Fired on click. / Fire khi click.
  AdEventCallback? onAdClicked;

  /// Fired when the SDK reports the load itself failed.
  /// Fire khi SDK báo load thất bại.
  Function(Ad? ad, LoadAdError error)? onAdFailedToLoad;

  final StreamController<AdStatus> _streamController =
      StreamController.broadcast();

  /// Broadcast stream of [AdStatus] transitions for this controller.
  /// Use it to drive UI (e.g. `StreamBuilder`) reacting to load /
  /// impression / dismiss states.
  ///
  /// Stream broadcast các bước chuyển [AdStatus] của controller này. Dùng
  /// để drive UI (vd. `StreamBuilder`) phản ứng theo load / impression /
  /// dismiss.
  Stream<AdStatus> get stream => _streamController.stream;

  /// Latest known status; also pushed onto [stream].
  /// Status mới nhất; cũng được push vào [stream].
  AdStatus status = AdStatus.init;

  /// Load the underlying SDK ad. Override in subclasses.
  /// Load SDK ad. Override ở subclass.
  FutureOr<void> load() {}

  /// Convenience for subclasses that support reload (e.g. native /
  /// banner). Default no-op.
  ///
  /// Tiện ích cho subclass hỗ trợ reload (vd. native / banner). Mặc
  /// định no-op.
  void reload() {}

  /// Dispose the SDK ad while keeping the controller alive (callbacks
  /// still wired, [stream] still open). Use when you plan to [load]
  /// again later.
  ///
  /// Dispose SDK ad nhưng controller vẫn sống (callback vẫn nối, [stream]
  /// vẫn mở). Dùng khi sẽ [load] lại sau.
  FutureOr<void> disposeAd() {}

  /// Full teardown: [disposeAd] + close the event [stream]. Call when
  /// the widget owning this controller unmounts.
  ///
  /// Dọn dẹp hoàn toàn: [disposeAd] + đóng [stream]. Gọi khi widget sở
  /// hữu controller unmount.
  Future<void> dispose() async {
    await disposeAd();
    _streamController.close();
  }

  void addEvent({
    required AdStatus status,
    AdError? error,
    required String adId,
    double? valueMicros,
    PrecisionType? precision,
    String? currencyCode,
  }) {
    final event = AdInformation(
      status: status,
      type: type,
      currencyCode: currencyCode,
      precision: precision,
      valueMicros: valueMicros,
      adId: adId,
      error: error,
      adKey: adKey,
    );
    this.status = status;
    if (_streamController.isClosed) {
      return;
    }
    _streamController.sink.add(status);
    if (MyAds.instance.enableEventLogger) {
      // Log event to console
      final message =
          '''Ad Key: $adKey\nAd Type: ${event.type}\nId: $adId\nStatus: ${event.status}''';
      if (event.error != null) {
        logger.e('$message\n${event.error?.message}');
      } else {
        logger.i(message);
      }
    }
    AdEventsStream.instance.addEvent(event);
    updateShowRate(status, adId);
  }

  /// Log show rate của quảng cáo
  void updateShowRate(
    AdStatus status,
    String adId,
  ) {
    if (adKey == null || !MyAds.instance.enableShowRateLogger) {
      return;
    }
    // Only log loaded and impression status
    if (status != AdStatus.loaded && status != AdStatus.impression) {
      return;
    }
    if (MyAds.instance.showRate[adKey] == null) {
      MyAds.instance.showRate[adKey!] = ShowRateInfo(
        adId: adId,
      );
    }
    final showRateInfo = MyAds.instance.showRate[adKey]!;
    switch (status) {
      case AdStatus.loaded:
        showRateInfo.request++;
        break;
      case AdStatus.impression:
        showRateInfo.impression++;
        break;
      default:
        break;
    }
    showRateInfo.showRate = showRateInfo.impression / showRateInfo.request;
    logger.w(MyAds.instance.showRate);
  }
}

/// Adds the fullscreen-specific show callbacks and the abstract [show]
/// hook. Subclasses for Interstitial / Rewarded / AppOpen extend this
/// (via [BaseFullScreenAdController]).
///
/// Mở rộng với callback show riêng cho fullscreen + hook [show] abstract.
/// Subclass cho Interstitial / Rewarded / AppOpen extend qua
/// [BaseFullScreenAdController].
abstract class FullScreenAdController extends AdController {
  FullScreenAdController({
    required super.adId,
    required super.type,
    super.adKey,
    this.onShowed,
    this.onAdFailedToShow,
  });

  /// Fired when the SDK confirms the fullscreen ad is on screen.
  /// Fire khi SDK xác nhận fullscreen ad đã hiện trên màn.
  AdEventCallback? onShowed;

  /// Fired when the SDK reports the show step failed (load succeeded
  /// but presentation didn't).
  ///
  /// Fire khi SDK báo bước show failed (load thành công nhưng không
  /// trình bày được).
  Function(Ad? ad, AdError error)? onAdFailedToShow;

  Future<void> show({bool immersiveModeEnabled = true});
}

/// Generic base for the 3 fullscreen ad types (Interstitial / Rewarded /
/// AppOpen). Owns the load + show + dispose flow; subclasses only map
/// the SDK-specific entry points.
///
/// Lớp cơ sở generic cho 3 fullscreen ad (Interstitial / Rewarded /
/// AppOpen). Giữ flow load + show + dispose; subclass chỉ map các entry
/// point đặc thù của SDK.
///
/// Subclass implements three hooks:
/// - [loadSdkAd]: invoke `XxxAd.load(...)` of the underlying SDK.
/// - [attachFullScreenCallbacks]: assign the typed
///   `fullScreenContentCallback` (use [buildStandardCallback]).
/// - [doShow]: invoke `ad.show(...)` of the underlying SDK.
///
/// Subclass implement 3 hook:
/// - [loadSdkAd]: gọi `XxxAd.load(...)` của SDK.
/// - [attachFullScreenCallbacks]: gán `fullScreenContentCallback` typed
///   (dùng [buildStandardCallback]).
/// - [doShow]: gọi `ad.show(...)` của SDK.
abstract class BaseFullScreenAdController<T extends AdWithoutView>
    extends FullScreenAdController {
  BaseFullScreenAdController({
    required super.adId,
    required super.type,
    super.adKey,
  });

  T? _ad;
  LoadAdError? _error;

  /// The current SDK ad instance, or `null` if not loaded / already
  /// dismissed.
  ///
  /// Instance SDK ad hiện tại, hoặc `null` nếu chưa load / đã dismiss.
  T? get ad => _ad;

  /// Hook — call `XxxAd.load(...)` of the SDK and forward the callbacks
  /// to [onAdLoaded] / [onAdFailedToLoad].
  ///
  /// Hook — gọi `XxxAd.load(...)` của SDK rồi forward callback về
  /// [onAdLoaded] / [onAdFailedToLoad].
  void loadSdkAd({
    required String adUnitId,
    required void Function(T ad) onAdLoaded,
    required void Function(LoadAdError error) onAdFailedToLoad,
  });

  /// Hook — assign the SDK's typed `fullScreenContentCallback`. Use
  /// [buildStandardCallback] to get the standard body and just pass it
  /// through.
  ///
  /// Hook — gán `fullScreenContentCallback` typed của SDK. Dùng
  /// [buildStandardCallback] để lấy body chuẩn rồi pass thẳng.
  void attachFullScreenCallbacks(T ad);

  /// Hook — invoke `ad.show(...)` of the SDK. Reward overrides to pass
  /// the `onUserEarnedReward` argument.
  ///
  /// Hook — gọi `ad.show(...)` của SDK. Reward override để truyền
  /// `onUserEarnedReward`.
  Future<void> doShow(T ad);

  @override
  Future<void> load() async {
    _ad = await _loadAd(id: adId);
    if (_ad == null) {
      addEvent(status: AdStatus.loadFailed, adId: adId);
      MyAds.instance.setFullscreenAdShowing(false);
      onAdFailedToLoad?.call(
          null, _error ?? LoadAdError(0, '', 'Id is empty', null));
    } else {
      onLoaded?.call(_ad!);
      addEvent(status: AdStatus.loaded, adId: _ad!.adUnitId);
    }
  }

  Future<T?> _loadAd({required String id}) async {
    if (id.isEmpty) return null;
    if (status.isLoading || status.isLoaded || !MyAds.instance.hasInternet) {
      return _ad;
    }
    addEvent(status: AdStatus.loading, adId: id);
    final completer = MyCompleter<T?>();
    loadSdkAd(
      adUnitId: id,
      onAdLoaded: (ad) {
        _wirePaidEvent(ad);
        attachFullScreenCallbacks(ad);
        completer.complete(ad);
      },
      onAdFailedToLoad: (error) {
        _error = error;
        completer.complete();
      },
    );
    return completer.future;
  }

  void _wirePaidEvent(T ad) {
    ad.onPaidEvent = (paidAd, valueMicros, precision, currencyCode) {
      addEvent(
        status: AdStatus.paid,
        adId: paidAd.adUnitId,
        valueMicros: valueMicros,
        precision: precision,
        currencyCode: currencyCode,
      );
      onPaidEvent?.call(paidAd, valueMicros, precision, currencyCode);
    };
  }

  /// Build the standard `FullScreenContentCallback` body that emits
  /// status events, toggles [MyAds.isFullscreenAdShowing], and disposes
  /// the SDK ad on failure/dismiss.
  ///
  /// Tạo body chuẩn cho `FullScreenContentCallback`: emit status event,
  /// toggle [MyAds.isFullscreenAdShowing], và dispose SDK ad khi
  /// failure/dismiss.
  ///
  /// [onDismissedExtra] runs *before* the SDK ad is disposed, so
  /// subclasses (e.g. Interstitial's `reloadOnDismiss`) can act on the
  /// still-valid ad reference.
  ///
  /// [onDismissedExtra] chạy *trước* khi SDK ad dispose, để subclass (vd.
  /// `reloadOnDismiss` của Interstitial) có thể thao tác với ad reference
  /// còn hiệu lực.
  FullScreenContentCallback<U> buildStandardCallback<U extends Ad>({
    void Function(U ad)? onDismissedExtra,
  }) {
    return FullScreenContentCallback<U>(
      onAdShowedFullScreenContent: (ad) {
        MyAds.instance.setFullscreenAdShowing(true);
        addEvent(status: AdStatus.shown, adId: ad.adUnitId);
        onShowed?.call(ad);
      },
      onAdFailedToShowFullScreenContent: (ad, err) {
        MyAds.instance.setFullscreenAdShowing(false);
        _ad = null;
        ad.dispose();
        addEvent(status: AdStatus.showFailed, error: err, adId: ad.adUnitId);
        onAdFailedToShow?.call(ad, err);
      },
      onAdDismissedFullScreenContent: (ad) {
        MyAds.instance.setFullscreenAdShowing(false);
        _ad = null;
        onDismissedExtra?.call(ad);
        ad.dispose();
        addEvent(status: AdStatus.dismiss, adId: ad.adUnitId);
        onDismissed?.call(ad);
      },
      onAdImpression: (ad) {
        addEvent(status: AdStatus.impression, adId: ad.adUnitId);
        onAdImpression?.call(ad);
      },
      onAdClicked: (ad) {
        addEvent(status: AdStatus.clicked, adId: ad.adUnitId);
        onAdClicked?.call(ad);
      },
    );
  }

  @override
  Future<void> show({bool immersiveModeEnabled = true}) async {
    final localAd = _ad;
    if (localAd == null) return;
    await localAd.setImmersiveMode(immersiveModeEnabled);
    await doShow(localAd);
  }

  @override
  Future<void> disposeAd() async {
    await _ad?.dispose();
    addEvent(status: AdStatus.init, adId: _ad?.adUnitId ?? adId);
    _ad = null;
  }
}
