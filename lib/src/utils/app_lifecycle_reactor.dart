import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_ads_plus/src/widget/full_native_ad.dart';

import '../../flutter_ads_plus.dart';

/// Reacts to app foreground/background transitions to show an "app-open
/// resume" ad, optionally overlaid with a native-format ad.
///
/// Lắng nghe app đi/về foreground để show "app-open resume" ad, tuỳ chọn
/// có thể phủ thêm native-format ad lên trên.
///
/// Created once by [MyAds.initialize]. Configure via:
/// - [configAppOpen]: set the main app-open ad id (called by
///   [MyAds.initAppOpenAd]).
/// - [configNativeFull]: set an optional native-format ad to overlay
///   (requires [MyAds.enableNativeFullResume]).
/// - [setSingleUseAdId]: one-shot override of the next resume show
///   (e.g. for a special promo); reverts after one show / fail.
/// - [setIsExcludeScreen]: temporarily skip the next resume show
///   (auto-reset after one transition).
///
/// Tạo 1 lần bởi [MyAds.initialize]. Cấu hình qua:
/// - [configAppOpen]: set ad id chính (được gọi bởi [MyAds.initAppOpenAd]).
/// - [configNativeFull]: set native-format ad phủ lên (cần
///   [MyAds.enableNativeFullResume]).
/// - [setSingleUseAdId]: override 1-lần cho lần resume tiếp theo (vd.
///   promo); reset sau 1 lần show / fail.
/// - [setIsExcludeScreen]: bỏ qua resume show tiếp theo (auto reset sau
///   1 transition).
class AppLifecycleReactor {
  final GlobalKey<NavigatorState> navigatorKey;
  String? _mainAppOpenId;
  String? _singleUseAdId;
  bool _showLoading = true;

  NativeAdController? nativeFullAdController;

  /// Effective ad id for the next resume show: single-use takes
  /// precedence when set + non-empty, otherwise falls back to the main id.
  ///
  /// Ad id thực dùng cho lần resume tiếp theo: ưu tiên single-use khi đã
  /// set + không rỗng, ngược lại dùng main id.
  String? get appOpenAdId {
    final s = _singleUseAdId;
    if (s != null && s.isNotEmpty) return s;
    return _mainAppOpenId;
  }

  /// `true` to skip the next app-open resume show (e.g. while a Sign-In
  /// flow is active). Auto-reset to `false` after one state transition.
  ///
  /// Đặt `true` để bỏ qua lần app-open resume tiếp theo (vd. khi đang
  /// trong flow Sign-In). Tự reset về `false` sau 1 state transition.
  bool isExcludeScreen = false;

  /// Master switch — when `false`, the reactor never auto-shows. Toggled
  /// by [setShouldShow]. Disabled by default; [MyAds.initAppOpenAd]
  /// enables it (unless `autoEnable: false`).
  ///
  /// Công tắc tổng — khi `false`, reactor không tự show. Bật/tắt qua
  /// [setShouldShow]. Mặc định tắt; [MyAds.initAppOpenAd] sẽ bật (trừ khi
  /// `autoEnable: false`).
  bool shouldShow = false;

  /// Configured via [setTimeLimit] from
  /// [MyAds.initialize.timeShowAdInterAfterAdOpen]. Used both as the
  /// "cooldown" after an app-open before re-enabling interstitials, and
  /// as the minimum interval between an inter dismiss and a subsequent
  /// app-open resume.
  ///
  /// Set qua [setTimeLimit] từ
  /// [MyAds.initialize.timeShowAdInterAfterAdOpen]. Dùng cho 2 mục đích:
  /// (1) cooldown sau app-open trước khi cho phép inter trở lại, (2)
  /// khoảng cách tối thiểu giữa inter dismiss và app-open resume kế tiếp.
  int _timeLimit = 0;

  /// `false` during the cooldown window after an app-open show. Read by
  /// [MyAds._canShowInter] to block interstitials during cooldown.
  ///
  /// `false` trong cửa sổ cooldown sau khi app-open show. Được
  /// [MyAds._canShowInter] đọc để chặn inter trong lúc cooldown.
  bool shouldShowInter = true;

  bool _immersiveModeEnabled = true;

  AppLifecycleReactor({
    required this.navigatorKey,
  });

  void listenToAppStateChanges() {
    AppStateEventNotifier.startListening();
    AppStateEventNotifier.appStateStream.listen(_onAppStateChanged);
  }

  void setShouldShow(bool value) {
    shouldShow = value;
  }

  void setTimeLimit(int value) {
    _timeLimit = value;
  }

  Timer? _timer;

  /// Schedule re-enabling interstitials [_timeLimit] seconds from now,
  /// resetting any previously scheduled timer. Called after an
  /// app-open-resume dismiss.
  ///
  /// Lên lịch bật lại inter sau [_timeLimit] giây, huỷ timer cũ nếu có.
  /// Gọi sau khi app-open-resume dismiss.
  void setShouldShowInter() {
    if (_timeLimit == 0) {
      return;
    }
    if (_timer != null && _timer!.isActive) {
      _timer!.cancel();
    }
    _timer = Timer(
      Duration(seconds: _timeLimit),
      () {
        shouldShowInter = true;
      },
    );
  }

  /// One-shot exclusion: the next foreground transition skips the
  /// app-open ad, then this flag resets itself to `false`.
  ///
  /// Loại trừ 1-lần: lần next foreground transition sẽ bỏ qua app-open,
  /// sau đó cờ tự reset về `false`.
  void setIsExcludeScreen(bool value) {
    isExcludeScreen = value;
  }

  /// Hide the navigation/status bars while the app-open ad is on screen
  /// (Android only — iOS no-op).
  ///
  /// Ẩn thanh điều hướng / thanh trạng thái khi app-open ad đang hiển thị
  /// (chỉ Android — iOS no-op).
  void setImmersiveMode(bool value) {
    _immersiveModeEnabled = value;
  }

  /// Main app-open ad id used by the resume flow. Called by
  /// [MyAds.initAppOpenAd] — direct usage rarely needed.
  ///
  /// Ad id chính cho app-open resume. Được [MyAds.initAppOpenAd] gọi —
  /// hiếm khi cần gọi trực tiếp.
  void configAppOpen({
    String? id,
    bool showLoading = true,
  }) {
    _mainAppOpenId = id;
    _showLoading = showLoading;
  }

  /// Configure the native-format ad to overlay on top of the app-open
  /// resume ad. Only triggered when [MyAds.enableNativeFullResume] is
  /// `true`. The `factoryId` must match the native side; here it's
  /// hardcoded to `'fullNativeAd'`.
  ///
  /// Cấu hình native-format ad phủ lên app-open resume. Chỉ trigger khi
  /// [MyAds.enableNativeFullResume] = `true`. `factoryId` phải khớp với
  /// native; ở đây hardcode `'fullNativeAd'`.
  void configNativeFull({
    required String id,
  }) {
    nativeFullAdController = NativeAdController(
      adId: id,
      factoryId: 'fullNativeAd',
      adKey: 'native_full_app_open',
      reloadOnClicked: false,
    );
  }

  /// Override the next resume show with [id] just once. Cleared inside
  /// [_onAppStateChanged] after the show settles.
  ///
  /// Override ad id cho duy nhất lần resume tiếp theo. Clear bên trong
  /// [_onAppStateChanged] sau khi show settle.
  void setSingleUseAdId({
    String? id,
  }) {
    _singleUseAdId = id;
  }

  /// Returns `true` if enough time has passed since the last interstitial
  /// to allow showing an app-open resume. Acts as inter↔open spacing.
  ///
  /// Trả `true` nếu đã đủ thời gian từ inter gần nhất để cho phép show
  /// app-open resume. Đóng vai trò khoảng cách inter↔open.
  bool _checkShowAdOpen() {
    if (MyAds.instance.interLastTime == null) {
      return true;
    }
    Duration difference =
        DateTime.now().difference(MyAds.instance.interLastTime!);
    if (difference.inSeconds > _timeLimit) {
      return true;
    }
    return false;
  }

  void _onAppStateChanged(AppState appState) async {
    final validId = appOpenAdId != null;
    if (!validId || appState == AppState.background || !shouldShow) {
      return;
    }
    // One-shot exclusion: skip this show then auto-clear.
    // Loại trừ 1-lần: bỏ qua show này rồi auto-clear.
    if (isExcludeScreen) {
      isExcludeScreen = false;
      return;
    }
    if (navigatorKey.currentContext == null) {
      return;
    }
    if (MyAds.instance.isFullscreenAdShowing) {
      return;
    }
    if (!_checkShowAdOpen()) {
      return;
    }

    // Start cooldown: block interstitials until [setShouldShowInter]'s
    // timer expires.
    // Bắt đầu cooldown: chặn inter cho đến khi timer của
    // [setShouldShowInter] hết hạn.
    if (_timeLimit > 0) {
      shouldShowInter = false;
    }

    // Small delay so the new route is mounted before showing the ad.
    // Delay nhỏ để route mới mount xong trước khi show ad.
    await Future.delayed(const Duration(milliseconds: 50));

    MyAds.instance.showAppOpenAd(
      navigatorKey.currentContext!,
      adId: appOpenAdId ?? '',
      adKey: 'app_open_resume',
      immersiveModeEnabled: _immersiveModeEnabled,
      showLoading: _showLoading,
      adDismissed: () {
        _singleUseAdId = null;
        setShouldShowInter();
      },
      onFailed: () {
        _singleUseAdId = null;
      },
      onShowed: () {
        if (nativeFullAdController == null ||
            !MyAds.instance.enableNativeFullResume) {
          return;
        }
        final status = nativeFullAdController!.status;
        if (!status.isLoading && !status.isShowOnScreen) {
          nativeFullAdController?.load();
        }
        showFullNativeAd(
            controller: nativeFullAdController!, showLoading: _showLoading);
      },
    );
  }
}
