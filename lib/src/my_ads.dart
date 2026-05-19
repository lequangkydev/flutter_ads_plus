import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_ads_plus/flutter_ads_plus.dart';
import 'package:flutter_ads_plus/src/utils/logger.dart';
import 'package:flutter_ads_plus/src/utils/my_completer.dart';
import 'package:flutter_ads_plus/src/widget/app_open_ad.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';

/// Main entry point for the ads plugin — singleton wrapper over
/// `google_mobile_ads` that also bridges to the native preload pipeline.
///
/// Tâm điểm của plugin: singleton bọc `google_mobile_ads` + cầu nối sang
/// native preload (PreloadV2 trên Android/iOS).
///
/// Two show paths exist for fullscreen ads:
/// - **Preload path**: if a native-preloaded ad is available for the given
///   ad unit id, it is shown immediately via MethodChannel (no Dart load
///   round-trip).
/// - **Default fallback**: if no preload is available, a fresh
///   `XxxAd.load()` is performed through the matching controller widget
///   (`MyInterstitialAd`, `MyRewardedAd`, `MyAppOpenAd`).
///
/// Hai đường show cho fullscreen ads:
/// - **Preload path**: nếu native đã preload sẵn cho adUnitId, show ngay
///   qua MethodChannel (không cần load lại từ Dart).
/// - **Default fallback**: nếu chưa preload, gọi `XxxAd.load()` qua
///   controller widget tương ứng.
///
/// Typical bootstrap (Khởi tạo điển hình):
/// ```dart
/// await MyAds.instance.initialize(navigatorKey: navigatorKey);
/// MyAds.instance.initAppOpenAd(appOpenAdUnitId: '...');
/// await MyAds.instance.preloadInterstitialAd(adId: '...');
/// ```
class MyAds {
  MyAds._myAds();

  static final MyAds instance = MyAds._myAds();

  /// Reacts to app foreground/background transitions to show the app-open
  /// resume ad. Created by [initialize], `null` until then.
  ///
  /// Lắng nghe app vào/ra foreground để show app-open-resume ad. Tạo ra
  /// bởi [initialize], `null` cho đến khi [initialize] chạy xong.
  AppLifecycleReactor? appLifecycleReactor;

  AdRequest _adRequest = const AdRequest();

  AdRequest get adRequest => _adRequest;

  bool _isFullscreenAdShowing = false;

  /// Set the global "a fullscreen ad is currently visible" flag. Used by
  /// internal logic to prevent stacking; widget code rarely needs to call
  /// this directly.
  ///
  /// Đặt cờ "đang có fullscreen ad hiện thị". Dùng nội bộ để chặn show
  /// chồng; widget code hiếm khi cần gọi trực tiếp.
  void setFullscreenAdShowing(bool value) => _isFullscreenAdShowing = value;

  /// `true` while a fullscreen ad (interstitial / rewarded / app-open) is
  /// on screen. Banner / native widgets read this to skip resume reloads
  /// while the fullscreen takes focus.
  ///
  /// `true` khi fullscreen ad đang hiển thị. Banner / native widgets dựa
  /// vào cờ này để bỏ qua reload-on-resume trong lúc fullscreen đang chiếm
  /// màn hình.
  bool get isFullscreenAdShowing => _isFullscreenAdShowing;

  /// Anchored adaptive banner size measured at [initialize] time. May be
  /// `null` briefly during startup until the async measurement completes.
  ///
  /// Kích thước anchored-adaptive banner đo lúc [initialize]. Có thể `null`
  /// trong khoảnh khắc đầu cho đến khi measurement async xong.
  AdSize? bannerAdSize;

  late GlobalKey<NavigatorState> navigatorKey;

  /// Tracked from [InternetConnection]. Defaults to `true` so the first
  /// load attempt doesn't get blocked before the first check returns.
  ///
  /// Theo dõi qua [InternetConnection]. Mặc định `true` để lần load đầu
  /// không bị chặn trước khi check kết nối đầu tiên trả về.
  bool hasInternet = true;

  /// When `true`, every status change (load / show / dismiss / paid / ...)
  /// is logged via the package logger. Useful during development.
  ///
  /// Bật `true` để log mọi status (load / show / dismiss / paid / ...) qua
  /// package logger. Hữu ích lúc dev.
  bool enableEventLogger = true;

  /// When `true`, the per-`adKey` show-rate is recomputed on every load /
  /// impression and logged. See [showRate].
  ///
  /// Bật `true` để tính lại show-rate theo `adKey` mỗi lần load / impression
  /// và log ra. Xem [showRate].
  bool enableShowRateLogger = true;

  /// Global default for [NativeAdController.reloadOnClicked] when the
  /// controller's own flag is `null`. When `true`, native ads are
  /// auto-reloaded after a user click.
  ///
  /// Mặc định toàn cục cho [NativeAdController.reloadOnClicked] khi cờ của
  /// controller là `null`. Bật `true` để native ads tự reload sau khi click.
  bool reloadNativeAdWhenClicked = false;

  /// Minimum seconds between two consecutive (non-forced) interstitial
  /// shows. Lets you throttle interstitial frequency app-wide.
  ///
  /// Khoảng cách tối thiểu (giây) giữa 2 inter ad liên tiếp (khi không
  /// forceShow). Dùng để throttle tần suất inter ở scope toàn app.
  int interIntervalInSeconds = 20;

  /// Timestamp of the last interstitial dismiss. Internal — used by
  /// [checkInterInterval]; mutated when an interstitial is dismissed.
  ///
  /// Thời điểm dismiss của inter ad gần nhất. Nội bộ — [checkInterInterval]
  /// đọc, được set khi inter dismiss.
  DateTime? interLastTime;

  /// Broadcast stream of every ad event across all controllers and the
  /// native preload bridge. Subscribe for analytics or custom routing.
  ///
  /// Stream broadcast mọi ad event từ tất cả controller + native preload.
  /// Subscribe cho analytics hoặc custom routing.
  Stream<AdInformation> get events => AdEventsStream.instance.stream;

  /// Per-`adKey` impression / request counts, kept in memory and logged
  /// when [enableShowRateLogger] is on. Lifetime is the process lifetime.
  ///
  /// Đếm impression / request theo `adKey`, giữ trong RAM, log ra khi
  /// [enableShowRateLogger]. Đời sống = đời sống process.
  final Map<String, ShowRateInfo> showRate = {};

  bool initialized = false;

  bool _enableNativeFullResume = false;

  /// When `true`, the [AppLifecycleReactor] overlays a native-format ad on
  /// top of the app-open resume ad. Toggle from Remote Config to A/B
  /// test this layout. Off by default.
  ///
  /// Bật `true` để [AppLifecycleReactor] phủ native-format ad lên trên
  /// app-open resume ad. Có thể bật/tắt qua Remote Config để A/B test.
  /// Mặc định tắt.
  bool get enableNativeFullResume => _enableNativeFullResume;

  void setEnableNativeFullResume(bool value) {
    _enableNativeFullResume = value;
  }

  /// One-shot bootstrap. Safe to call multiple times — only the first call
  /// has effect (subsequent calls log a warning and return).
  ///
  /// Khởi tạo một lần. Gọi lại không sao — chỉ lần đầu có tác dụng, các
  /// lần sau chỉ log warning rồi return.
  ///
  /// - [navigatorKey]: required to overlay loading widgets and read screen
  ///   width for the anchored banner size. Same key as your `MaterialApp`.
  ///   Bắt buộc để overlay loading widget và đo bề rộng cho anchored
  ///   banner. Dùng đúng key đã pass vào `MaterialApp`.
  /// - [adMobAdRequest]: custom [AdRequest] applied to every Dart-side
  ///   load. Native preload uses its own request internally.
  ///   `AdRequest` tuỳ chỉnh dùng cho mọi load từ Dart. Native preload
  ///   dùng request riêng bên trong.
  /// - [admobConfiguration]: forwarded to `MobileAds.instance` (test
  ///   device ids, child-directed, etc.).
  ///   Forward sang `MobileAds.instance` (test device, child-directed...).
  /// - [interIntervalInSeconds]: throttle between non-forced interstitial
  ///   shows. Default 20s.
  ///   Khoảng cách tối thiểu giữa 2 inter (khi không forceShow). Mặc định
  ///   20 giây.
  /// - [timeShowAdInterAfterAdOpen]: minimum seconds between an inter
  ///   dismiss and the next app-open-resume show; also re-enables
  ///   interstitials this long after an app-open shows. Pass `null` or
  ///   `0` to disable.
  ///   Số giây tối thiểu giữa lúc inter dismiss và lúc cho phép app-open-
  ///   resume show; cũng là thời gian "khoá" inter sau khi app-open show.
  ///   Truyền `null` / `0` để tắt.
  /// - [fullScreenLoadingConfig]: pick the loading overlay style (Lottie,
  ///   video, or a custom widget). See [FullScreenLoadingConfig].
  ///   Chọn kiểu loading overlay (Lottie / video / widget tuỳ chỉnh).
  ///   Xem [FullScreenLoadingConfig].
  Future<void> initialize({
    AdRequest? adMobAdRequest,
    RequestConfiguration? admobConfiguration,
    bool enableEventLogger = true,
    bool enableShowRateLogger = false,
    bool reloadNativeAdWhenClicked = false,
    required GlobalKey<NavigatorState> navigatorKey,
    int? timeShowAdInterAfterAdOpen,
    int interIntervalInSeconds = 20,
    FullScreenLoadingConfig? fullScreenLoadingConfig,
  }) async {
    if (initialized) {
      logger.w('MyAds already initialized');
      return;
    }

    this.interIntervalInSeconds = interIntervalInSeconds;
    this.navigatorKey = navigatorKey;
    this.enableEventLogger = enableEventLogger;
    this.enableShowRateLogger = enableShowRateLogger;
    this.reloadNativeAdWhenClicked = reloadNativeAdWhenClicked;

    if (adMobAdRequest != null) {
      _adRequest = adMobAdRequest;
    }
    FullScreenAdLoading.instance.preloadAnimations(fullScreenLoadingConfig);

    // Fire-and-forget: hasInternet stays `true` until the first check
    // resolves; subsequent changes are picked up via onStatusChange.
    // Fire-and-forget: hasInternet để `true` đến khi check đầu xong; thay
    // đổi sau được cập nhật qua onStatusChange.
    _checkingInternet();

    await MobileAds.instance.initialize();

    if (admobConfiguration != null) {
      MobileAds.instance.updateRequestConfiguration(admobConfiguration);
    }

    appLifecycleReactor = AppLifecycleReactor(navigatorKey: navigatorKey);
    appLifecycleReactor!.listenToAppStateChanges();
    if (timeShowAdInterAfterAdOpen != null && timeShowAdInterAfterAdOpen > 0) {
      appLifecycleReactor?.setTimeLimit(timeShowAdInterAfterAdOpen);
    }

    // Async measurement; [bannerAdSize] may stay null for a moment.
    // Banner controllers fall back to [AdSize.banner] if still null.
    // Đo bất đồng bộ; [bannerAdSize] có thể `null` trong khoảnh khắc.
    // Banner controller fallback về [AdSize.banner] nếu vẫn null.
    if (navigatorKey.currentContext != null) {
      AdSize.getLargeAnchoredAdaptiveBannerAdSize(
              MediaQuery.of(navigatorKey.currentContext!).size.width.round())
          .then((value) {
        bannerAdSize = value;
      });
    }

    initialized = true;
  }

  /// Configure the app-open-resume ad shown when the app comes back to
  /// foreground. Call once after [initialize].
  ///
  /// Cấu hình app-open-resume ad (show khi app trở lại foreground). Gọi 1
  /// lần sau [initialize].
  ///
  /// - [autoEnable]: when `true`, enables auto-show immediately. Set to
  ///   `false` if you want to delay enabling until later (e.g. after a
  ///   consent flow), then call
  ///   `MyAds.instance.appLifecycleReactor?.setShouldShow(true)`.
  ///   Bật `true` để tự show ngay. Đặt `false` nếu muốn delay enable đến
  ///   sau (vd. sau consent flow), rồi gọi
  ///   `MyAds.instance.appLifecycleReactor?.setShouldShow(true)`.
  /// - [nativeFullAdId]: optional native ad shown on top of the app-open
  ///   ad. Requires [enableNativeFullResume] = `true` to trigger.
  ///   Native ad tùy chọn phủ lên app-open ad. Cần [enableNativeFullResume]
  ///   = `true` mới trigger.
  /// - [bufferSize]: when > 0, kicks off a native preload with this
  ///   buffer immediately. `0` means "do not preload here" (you can still
  ///   call [preloadAppOpenAd] later).
  ///   `> 0` để khởi động native preload ngay với buffer này. `0` = không
  ///   preload tại đây (vẫn có thể gọi [preloadAppOpenAd] sau).
  void initAppOpenAd({
    required String appOpenAdUnitId,
    bool autoEnable = true,
    bool immersiveModeEnabled = true,
    String? nativeFullAdId,
    bool showLoading = true,
    int bufferSize = 0,
  }) {
    if (autoEnable) {
      appLifecycleReactor?.setShouldShow(true);
    }
    appLifecycleReactor?.setImmersiveMode(immersiveModeEnabled);
    appLifecycleReactor?.configAppOpen(
      id: appOpenAdUnitId,
      showLoading: showLoading,
    );
    if (nativeFullAdId != null) {
      appLifecycleReactor?.configNativeFull(
        id: nativeFullAdId,
      );
    }
    if (bufferSize > 0) {
      preloadAppOpenAd(
        adId: appOpenAdUnitId,
        bufferSize: bufferSize,
      );
    }
  }

  /// Ask the native side to preload an app-open ad into its buffer. The
  /// returned Future resolves when the first preload event fires (loaded /
  /// exhausted / failed) or after a 10s safety timeout.
  ///
  /// Yêu cầu native preload app-open ad vào buffer. Future resolve khi
  /// event preload đầu fire (loaded / exhausted / failed) hoặc sau 10s
  /// safety timeout.
  ///
  /// - [bufferSize]: how many ads to keep warmed. Default 1 is enough for
  ///   most apps. Higher values reduce empty-buffer windows but consume
  ///   more inventory.
  ///   Số ad giữ sẵn. Mặc định 1 là đủ. Lớn hơn giảm khoảng buffer rỗng
  ///   nhưng tốn inventory hơn.
  Future<void> preloadAppOpenAd({
    required String adId,
    int bufferSize = 1,
    Function()? onAdPreloaded,
    Function(int code, String message, String domain)? onAdFailedToPreload,
    Function()? onAdsExhausted,
  }) async {
    return _handlePreloadGeneric(
      adId: adId,
      bufferSize: bufferSize,
      isAdAvailableFn: NativeAppOpenPreloadUtil.isAdAvailable,
      preloadFn: NativeAppOpenPreloadUtil.preload,
      eventsStream: NativeAppOpenPreloadUtil.events,
      onAdPreloaded: onAdPreloaded,
      onAdFailedToPreload: onAdFailedToPreload,
      onAdsExhausted: onAdsExhausted,
    );
  }

  /// Ask the native side to preload an interstitial ad. See
  /// [preloadAppOpenAd] for parameter semantics.
  ///
  /// Yêu cầu native preload inter ad. Xem [preloadAppOpenAd] để hiểu
  /// param.
  Future<void> preloadInterstitialAd({
    required String adId,
    int bufferSize = 1,
    Function()? onAdPreloaded,
    Function(int code, String message, String domain)? onAdFailedToPreload,
    Function()? onAdsExhausted,
  }) async {
    return _handlePreloadGeneric(
      adId: adId,
      bufferSize: bufferSize,
      isAdAvailableFn: NativeInterPreloadUtil.isAdAvailable,
      preloadFn: NativeInterPreloadUtil.preload,
      eventsStream: NativeInterPreloadUtil.events,
      onAdPreloaded: onAdPreloaded,
      onAdFailedToPreload: onAdFailedToPreload,
      onAdsExhausted: onAdsExhausted,
    );
  }

  /// `true` if enough time has elapsed since the last interstitial dismiss
  /// (per [interIntervalInSeconds]) or no interstitial has been shown yet.
  ///
  /// `true` nếu đã qua đủ [interIntervalInSeconds] kể từ lần inter dismiss
  /// gần nhất, hoặc chưa có inter nào show.
  bool checkInterInterval() {
    if (interLastTime == null) {
      return true;
    }
    Duration difference = DateTime.now().difference(interLastTime!);
    return difference.inSeconds > interIntervalInSeconds;
  }

  /// Show the splash-time ad (interstitial by default, app-open if
  /// [useInterAd] = `false`). Uses the preload-first / fallback algorithm
  /// shared by [showInterstitialAd] / [showAppOpenAd].
  ///
  /// Show ad ở splash (mặc định inter, hoặc app-open nếu [useInterAd] =
  /// `false`). Dùng cùng thuật toán preload-trước / fallback của
  /// [showInterstitialAd] / [showAppOpenAd].
  ///
  /// Awaits until the ad is dismissed (preload path) or until the default
  /// fallback widget has been kicked off (which then continues async via
  /// its own controller callbacks).
  ///
  /// Await đến khi ad dismiss (preload path) hoặc đến khi default fallback
  /// widget đã start (sau đó tiếp tục async qua callback của controller).
  Future<void> showSplashAd(
    BuildContext context, {
    required String adId,
    Function()? onShowed,
    Function()? adDismissed,
    Function()? onFailed,
    Function()? onNoInternet,
    bool showLoading = true,
    bool immersiveModeEnabled = true,
    bool useInterAd = true,
  }) async {
    if (!hasInternet) {
      onNoInternet?.call();
      return;
    }

    if (useInterAd) {
      await _handleTryShowGeneric(
        context: context,
        adId: adId,
        onShowed: onShowed,
        onFailed: onFailed,
        adKey: 'splash_inter',
        isAdAvailableFn: NativeInterPreloadUtil.isAdAvailable,
        showNativeFn: NativeInterPreloadUtil.show,
        eventsStream: NativeInterPreloadUtil.events,
        adType: AdType.interstitial,
        adDismissed: adDismissed,
        showDefaultFallback: (effectiveId) {
          _showDefaultInterstitialAd(
            context,
            adId: effectiveId,
            adKey: 'splash_inter',
            onShowed: onShowed,
            adDismissed: adDismissed,
            onFailed: onFailed,
            showLoading: showLoading,
            immersiveModeEnabled: immersiveModeEnabled,
          );
        },
      );
    } else {
      await _handleTryShowGeneric(
        adId: adId,
        context: context,
        onShowed: onShowed,
        onFailed: onFailed,
        adDismissed: adDismissed,
        adKey: 'splash_app_open',
        isAdAvailableFn: NativeAppOpenPreloadUtil.isAdAvailable,
        showNativeFn: NativeAppOpenPreloadUtil.show,
        eventsStream: NativeAppOpenPreloadUtil.events,
        adType: AdType.appOpen,
        showDefaultFallback: (effectiveId) {
          _showDefaultAppOpenAd(
            context,
            adId: effectiveId,
            adKey: 'splash_app_open',
            adDismissed: adDismissed,
            onShowed: onShowed,
            onFailed: onFailed,
            immersiveModeEnabled: immersiveModeEnabled,
            showLoading: showLoading,
          );
        },
      );
    }
  }

  /// Show a rewarded ad. If a fullscreen ad is already on screen,
  /// [onFailed] fires immediately and no ad is loaded.
  ///
  /// Show rewarded ad. Nếu đã có fullscreen ad đang hiển thị, [onFailed]
  /// được gọi ngay và không load thêm.
  ///
  /// - [controller]: pass to reuse a pre-loaded controller. When `null`,
  ///   a new controller is created from [adId] and loaded.
  ///   Truyền vào để tái dùng controller đã load. Nếu `null`, tạo
  ///   controller mới từ [adId] và load.
  void showRewardAd(
    BuildContext context, {
    required String adId,
    String? adKey,
    RewardedAdController? controller,
    Function()? onShowed,
    Function()? adDismissed,
    Function()? onFailed,
    Function()? onUserEarnedReward,
    bool immersiveModeEnabled = true,
    bool showLoading = true,
  }) async {
    if (_isFullscreenAdShowing) {
      onFailed?.call();
      return;
    }
    MyRewardedAd(
      adId: adId,
      controller: controller,
      context: context,
      onShowed: onShowed,
      onFailed: onFailed,
      showLoading: showLoading,
      adDismissed: adDismissed,
      onUserEarnedReward: onUserEarnedReward,
      adKey: adKey,
      immersiveModeEnabled: immersiveModeEnabled,
    ).init();
  }

  /// Show an app-open ad (typically used as a splash variant or for
  /// custom resume flows; the auto-resume case is handled by
  /// [AppLifecycleReactor]).
  ///
  /// Show app-open ad (thường dùng cho splash variant hoặc custom resume
  /// flow; trường hợp auto-resume do [AppLifecycleReactor] xử lý).
  Future<void> showAppOpenAd(
    BuildContext context, {
    required String adId,
    String? adKey,
    Function()? adDismissed,
    Function()? onShowed,
    Function()? onFailed,
    bool immersiveModeEnabled = true,
    AppOpenAdController? controller,
    bool showLoading = true,
  }) async {
    if (_isFullscreenAdShowing) {
      onFailed?.call();
      return;
    }

    await _handleTryShowGeneric(
      context: context,
      adId: adId,
      isAdAvailableFn: NativeAppOpenPreloadUtil.isAdAvailable,
      showNativeFn: NativeAppOpenPreloadUtil.show,
      eventsStream: NativeAppOpenPreloadUtil.events,
      adType: AdType.appOpen,
      adKey: adKey ?? 'appOpenAd',
      onShowed: onShowed,
      adDismissed: adDismissed,
      onFailed: onFailed,
      onPaidExtra: (event) {
        final precision = PrecisionType.values[event.precisionType];
        controller?.onPaidEvent
            ?.call(null, event.value, precision, event.currencyCode);
      },
      showDefaultFallback: (effectiveId) {
        _showDefaultAppOpenAd(
          context,
          adId: effectiveId,
          adKey: adKey,
          adDismissed: adDismissed,
          onShowed: onShowed,
          onFailed: onFailed,
          immersiveModeEnabled: immersiveModeEnabled,
          controller: controller,
          showLoading: showLoading,
        );
      },
    );
  }

  /// Show an interstitial ad. Honors [interIntervalInSeconds] unless
  /// [forceShow] is `true`. If a fullscreen is already on screen, fails.
  ///
  /// Show inter ad. Tôn trọng [interIntervalInSeconds] trừ khi [forceShow]
  /// = `true`. Nếu đã có fullscreen đang hiển thị thì fail.
  ///
  /// - [forceShow]: bypass the interval throttle. Use sparingly (e.g.
  ///   splash flow). Also skips updating [interLastTime] so the next
  ///   non-forced show isn't blocked.
  ///   Bỏ qua interval throttle. Dùng tiết kiệm (vd. splash flow). Cũng
  ///   không update [interLastTime] để lần show non-forced tiếp theo không
  ///   bị chặn.
  Future<void> showInterstitialAd(
    BuildContext context, {
    required String adId,
    InterstitialAdController? controller,
    String? adKey,
    Function()? onShowed,
    Function()? adDismissed,
    Function()? onFailed,
    Function()? onNoInternet,
    Function()? onAdClicked,
    bool forceShow = false,
    bool showLoading = true,
    bool immersiveModeEnabled = true,
  }) async {
    if (!hasInternet) {
      onNoInternet?.call();
      return;
    }

    if (!_canShowInter(forceShow)) {
      onFailed?.call();
      return;
    }

    await _handleTryShowGeneric(
      context: context,
      adId: adId,
      isAdAvailableFn: NativeInterPreloadUtil.isAdAvailable,
      showNativeFn: NativeInterPreloadUtil.show,
      eventsStream: NativeInterPreloadUtil.events,
      adType: AdType.interstitial,
      adKey: adKey,
      onShowed: onShowed,
      adDismissed: () {
        if (!forceShow) interLastTime = DateTime.now();
        adDismissed?.call();
      },
      onFailed: onFailed,
      showDefaultFallback: (effectiveId) {
        _showDefaultInterstitialAd(
          context,
          adId: effectiveId,
          controller: controller,
          adKey: adKey,
          onShowed: onShowed,
          adDismissed: adDismissed,
          // Logic lưu interLastTime đã được xử lý bên trong _showDefaultInterstitialAd
          onFailed: onFailed,
          onAdClicked: onAdClicked,
          forceShow: forceShow,
          showLoading: showLoading,
          immersiveModeEnabled: immersiveModeEnabled,
        );
      },
    );
  }

  // ==========================================
  // --- HELPER ---
  // ==========================================

  /// Generic preload runner shared by [preloadAppOpenAd] and
  /// [preloadInterstitialAd]. Subscribes to the native event stream,
  /// invokes the native `startPreload`, and resolves on the first
  /// terminal event (preloaded / exhausted / failed) or a 10s timeout.
  ///
  /// Hàm preload generic dùng chung cho [preloadAppOpenAd] và
  /// [preloadInterstitialAd]. Subscribe stream native, gọi
  /// `startPreload`, resolve khi event terminal đầu (preloaded /
  /// exhausted / failed) hoặc sau 10s timeout.
  Future<void> _handlePreloadGeneric({
    required String adId,
    required int bufferSize,
    required Future<bool> Function(String) isAdAvailableFn,
    required Future<void> Function({required String adUnitId, int bufferSize})
        preloadFn,
    required Stream<BasePreloadEvent> eventsStream,
    Function()? onAdPreloaded,
    Function(int code, String message, String domain)? onAdFailedToPreload,
    Function()? onAdsExhausted,
  }) async {
    if (adId.isEmpty || bufferSize <= 0) return;

    final isAvailable = await isAdAvailableFn(adId);

    if (isAvailable) {
      onAdPreloaded?.call();
      return;
    }

    final completer = MyCompleter<void>();
    StreamSubscription<BasePreloadEvent>? sub;

    Timer? timeoutTimer;
    timeoutTimer = Timer(const Duration(seconds: 10), () {
      if (!completer.isCompleted) {
        sub?.cancel();
        completer.complete();
      }
    });

    sub = eventsStream
        .where((event) => event.adUnitId == adId)
        .listen((event) {
      if (event is AdPreloadedEvent) {
        onAdPreloaded?.call();
        completer.complete();
      } else if (event is AdFailedToPreloadEvent) {
        onAdFailedToPreload?.call(event.code, event.message, event.domain);
        completer.complete();
      } else if (event is AdsExhaustedEvent) {
        onAdsExhausted?.call();
        completer.complete();
      }
    });

    try {
      await preloadFn(adUnitId: adId, bufferSize: bufferSize);
      await completer.future;
    } catch (e) {
      logger.e('preload generic error: $e');
    } finally {
      sub.cancel();
      timeoutTimer.cancel();
    }
  }

  /// Preload-first show algorithm shared by all fullscreen show methods.
  ///
  /// 1. Ask native if a preloaded ad for [adId] is available.
  /// 2. If yes → subscribe to native events, call native `show`, await
  ///    dismiss / failure.
  /// 3. If no preloaded ad OR native `show` returns `false` → call
  ///    [showDefaultFallback] which runs the Dart-side load + show
  ///    through a `MyXxxAd` runner.
  ///
  /// Thuật toán preload-first dùng chung cho mọi show fullscreen.
  ///
  /// 1. Hỏi native xem có ad preloaded cho [adId] không.
  /// 2. Nếu có → subscribe stream native, gọi `show`, await dismiss /
  ///    failure.
  /// 3. Nếu không có HOẶC native `show` trả `false` → gọi
  ///    [showDefaultFallback] để load + show qua `MyXxxAd` runner ở Dart.
  Future<void> _handleTryShowGeneric({
    required BuildContext context,
    required String adId,
    required Future<bool> Function(String) isAdAvailableFn,
    required Future<bool> Function(String) showNativeFn,
    required Stream<BasePreloadEvent> eventsStream,
    required void Function(String effectiveId) showDefaultFallback,
    required AdType adType,
    String? adKey,
    Function()? onShowed,
    Function()? adDismissed,
    Function()? onFailed,
    Function(AdPaidEvent)? onPaidExtra,
  }) async {
    final hasPreloaded = await isAdAvailableFn(adId);

    if (!context.mounted) return;

    if (hasPreloaded) {
      final completer = MyCompleter<void>();
      StreamSubscription<BasePreloadEvent>? sub;

      sub = eventsStream
          .where((e) => e.adUnitId == adId)
          .listen((event) {
        if (event is AdShowedEvent) {
          setFullscreenAdShowing(true);
          onShowed?.call();
        } else if (event is AdDismissedEvent) {
          setFullscreenAdShowing(false);
          completer.complete();
          adDismissed?.call();
        } else if (event is AdFailedToShowEvent) {
          setFullscreenAdShowing(false);
          completer.complete();
          onFailed?.call();
        } else if (event is AdPaidEvent) {
          onPaidExtra?.call(event);
          final precision = PrecisionType.values[event.precisionType];
          _onAdPaid(
            valueMicros: event.valueMicros.toDouble(),
            precision: precision,
            currencyCode: event.currencyCode,
            adId: adId,
            type: adType,
            adKey: adKey,
          );
        }
      });

      try {
        final showed = await showNativeFn(adId);
        if (!showed) {
          // Native fail to start showing, fallback to default lib logic
          sub.cancel();
          showDefaultFallback(adId);
          setFullscreenAdShowing(false);
          completer.complete();
          return;
        }

        await completer.future;
      } catch (e) {
        logger.e('show $adType preload error: $e');
        completer.complete();
      } finally {
        sub.cancel();
      }
    } else {
      // If not preloaded, use the standard default logic
      showDefaultFallback(adId);
    }
  }

  void _showDefaultInterstitialAd(
    BuildContext context, {
    String? adId,
    InterstitialAdController? controller,
    String? adKey,
    Function()? onShowed,
    Function()? adDismissed,
    Function()? onFailed,
    Function()? onAdClicked,
    bool forceShow = false,
    bool showLoading = true,
    bool immersiveModeEnabled = true,
  }) {
    MyInterstitialAd(
      context: context,
      adId: adId,
      showLoading: showLoading,
      onShowed: onShowed,
      onFailed: onFailed,
      onAdClicked: onAdClicked,
      adKey: adKey,
      controller: controller,
      immersiveModeEnabled: immersiveModeEnabled,
      adDismissed: () {
        if (!forceShow) interLastTime = DateTime.now();
        adDismissed?.call();
      },
    ).init();
  }

  /// Combines all gates for a non-forced interstitial: no other
  /// fullscreen on screen, lifecycle reactor isn't in its post-app-open
  /// cooldown, and the [interIntervalInSeconds] throttle has elapsed.
  ///
  /// Gộp các điều kiện cho 1 inter non-forced: không có fullscreen khác
  /// đang show, lifecycle reactor không trong "cooldown sau app-open", và
  /// throttle [interIntervalInSeconds] đã qua.
  bool _canShowInter(bool forceShow) {
    if (forceShow) return true;
    if (_isFullscreenAdShowing) return false;
    if (appLifecycleReactor != null && !appLifecycleReactor!.shouldShowInter) {
      return false;
    }
    return checkInterInterval();
  }

  // ----------------------
  void _onAdPaid({
    required double valueMicros,
    required PrecisionType precision,
    required String currencyCode,
    required String adId,
    required AdType type,
    String? adKey,
  }) {
    final event = AdInformation(
      status: AdStatus.paid,
      type: type,
      currencyCode: currencyCode,
      precision: precision,
      valueMicros: valueMicros,
      adId: adId,
      adKey: adKey,
    );
    if (enableEventLogger) {
      logger.i(
          'Ad Paid (Preloaded)\nAd Key: $adKey\nAd Type: $type\nId: $adId\nValue: $valueMicros $currencyCode');
    }
    AdEventsStream.instance.addEvent(event);
  }

  void _showDefaultAppOpenAd(
    BuildContext context, {
    required String adId,
    String? adKey,
    Function()? adDismissed,
    Function()? onShowed,
    Function()? onFailed,
    bool immersiveModeEnabled = true,
    AppOpenAdController? controller,
    bool showLoading = true,
  }) {
    MyAppOpenAd(
      adId: adId,
      context: context,
      onShowed: onShowed,
      onFailed: onFailed,
      adDismissed: adDismissed,
      immersiveModeEnabled: immersiveModeEnabled,
      controller: controller,
      showLoading: showLoading,
      adKey: adKey ?? 'appOpenAd',
    ).init();
  }

  Future<void> _checkingInternet() async {
    hasInternet = await InternetConnection().hasInternetAccess;
    InternetConnection().onStatusChange.listen((status) {
      hasInternet = status == InternetStatus.connected;
    });
  }
}
