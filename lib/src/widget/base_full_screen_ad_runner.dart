import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_ads_plus/flutter_ads_plus.dart';

import '../utils/logger.dart';

/// One-shot helper that owns the lifecycle of showing a single
/// fullscreen ad: builds (or reuses) a controller, wires loading
/// overlay + status callbacks, defers the show if the app goes to
/// background, and disposes everything when done.
///
/// Helper 1-lần quản lý vòng đời show 1 fullscreen ad: tạo (hoặc tái
/// dùng) controller, wire loading overlay + status callback, hoãn show
/// nếu app vào background, dispose hết khi xong.
///
/// Subclass exposes its concrete ad type (`MyInterstitialAd`,
/// `MyRewardedAd`, `MyAppOpenAd`) and implements 2 hooks:
/// - [providedController]: a controller passed in by the user, or
///   `null` to let the runner build one from [adId].
/// - [buildController]: factory used when [providedController] is `null`.
/// - [attachExtraCallbacks]: optional — subclasses wire ad-type-specific
///   callbacks (e.g. `onAdClicked`, `onUserEarnedReward`).
///
/// Subclass expose ad type cụ thể (`MyInterstitialAd`, `MyRewardedAd`,
/// `MyAppOpenAd`) và implement 2 hook:
/// - [providedController]: controller user truyền vào, hoặc `null` để
///   runner tự build từ [adId].
/// - [buildController]: factory dùng khi [providedController] = `null`.
/// - [attachExtraCallbacks]: optional — wire callback đặc thù ad type
///   (vd. `onAdClicked`, `onUserEarnedReward`).
abstract class BaseFullScreenAdRunner<C extends FullScreenAdController> {
  BaseFullScreenAdRunner({
    this.adId,
    required this.context,
    this.onShowed,
    this.adDismissed,
    this.onFailed,
    this.adKey,
    this.immersiveModeEnabled = true,
    this.showLoading = true,
  });

  /// Used by [buildController] when no [providedController] is given.
  /// Dùng bởi [buildController] khi không có [providedController].
  final String? adId;

  final BuildContext context;
  final String? adKey;
  final bool immersiveModeEnabled;

  /// When `true`, the standard loading overlay is shown while loading.
  /// When `false`, the runner still pushes a transparent overlay after
  /// the ad shows so the underlying page can't be tapped through.
  ///
  /// `true`: hiển thị loading overlay chuẩn trong lúc load. `false`: vẫn
  /// push overlay trong suốt sau khi ad show để chặn tap xuyên xuống
  /// trang dưới.
  final bool showLoading;

  final void Function()? onShowed;
  final void Function()? onFailed;
  final void Function()? adDismissed;

  late final C _controller;
  bool _initialized = false;
  AppLifecycleListener? _appLifecycleListener;
  AppLifecycleState _appLifecycleState = AppLifecycleState.resumed;
  bool _adFailedToShow = false;

  /// Subclass: a user-provided controller, or `null` to build one from
  /// [adId]. / Subclass: controller user truyền sẵn, hoặc `null` để build
  /// từ [adId].
  C? get providedController;

  /// Subclass: factory invoked when [providedController] is `null`.
  /// Subclass: factory chạy khi [providedController] = `null`.
  C buildController();

  /// Subclass: wire ad-type-specific callbacks (e.g. `onAdClicked`,
  /// `onUserEarnedReward`). Default: no-op.
  ///
  /// Subclass: wire callback đặc thù ad type (vd. `onAdClicked`,
  /// `onUserEarnedReward`). Mặc định: no-op.
  void attachExtraCallbacks(C controller) {}

  /// Only show when the app is in foreground; otherwise mark it to be
  /// retried on resume (see [_appLifecycleListener]).
  ///
  /// Chỉ show khi app đang ở foreground; nếu không thì đánh dấu để retry
  /// khi resume (xem [_appLifecycleListener]).
  Future<void> _showAd() async {
    if (_appLifecycleState == AppLifecycleState.resumed) {
      await _controller.show(immersiveModeEnabled: immersiveModeEnabled);
    } else {
      _adFailedToShow = true;
    }
  }

  /// Wire up the controller, lifecycle listener, loading overlay, and
  /// status callbacks. Returns early (with [onFailed] fired) if neither a
  /// controller nor [adId] was provided.
  ///
  /// Wire controller, lifecycle listener, loading overlay, và status
  /// callback. Trả về sớm (kèm [onFailed]) nếu cả controller và [adId]
  /// đều không được cung cấp.
  void init() {
    if (MyAds.instance.isFullscreenAdShowing) {
      onFailed?.call();
      logger.e('Fullscreen ad is already showing');
      return;
    }
    final pc = providedController;
    if (pc != null) {
      _controller = pc;
      _initialized = true;
    } else if (adId != null) {
      _controller = buildController();
      _initialized = true;
      _controller.load();
    } else {
      logger.e('AdId or controller must be provided');
      onFailed?.call();
      return;
    }
    _appLifecycleListener = AppLifecycleListener(
      onStateChange: (value) {
        _appLifecycleState = value;
      },
      onResume: () {
        _appLifecycleState = AppLifecycleState.resumed;
        if (_adFailedToShow) _showAd();
      },
    );
    // Synchronously handle the case where the user passed an
    // already-loaded controller (preload pattern) — show immediately
    // instead of waiting for [onLoaded].
    // Xử lý đồng bộ trường hợp user truyền controller đã load (pattern
    // preload) — show luôn thay vì đợi [onLoaded].
    if (_controller.status.isLoaded) {
      _showAd();
    } else if (_controller.status.isLoadFailed) {
      _onLoadFailed();
    }
    // Push the overlay now so the host page can't be interacted with
    // during load + show. When the ad is already loaded we still push
    // the overlay but with [enableLoading: false] (transparent shield).
    // Push overlay ngay để chặn tương tác với trang dưới trong lúc load
    // + show. Khi ad đã loaded vẫn push overlay nhưng [enableLoading:
    // false] (lớp khiên trong suốt).
    if (showLoading &&
        !_controller.status.isLoadFailed &&
        !_controller.status.isDismiss) {
      FullScreenAdLoading.instance.showLoading(
        context,
        enableLoading: !_controller.status.isLoaded,
      );
    }
    MyAds.instance.setFullscreenAdShowing(true);
    _controller
      ..onLoaded = (ad) {
        _showAd();
      }
      ..onShowed = (ad) {
        FullScreenAdLoading.instance.hideLoadingWidget();
        if (!showLoading) {
          FullScreenAdLoading.instance.showLoading(
            context,
            enableLoading: false,
          );
        }
        onShowed?.call();
      }
      ..onAdFailedToShow = (ad, error) {
        if (_appLifecycleState != AppLifecycleState.resumed) {
          _adFailedToShow = true;
        }
        _controller.dispose();
        FullScreenAdLoading.instance.removeLoading();
        onFailed?.call();
      }
      ..onAdFailedToLoad = (ad, error) {
        _onLoadFailed();
      }
      ..onDismissed = (ad) {
        _controller.dispose();
        FullScreenAdLoading.instance.removeLoading();
        adDismissed?.call();
      };
    attachExtraCallbacks(_controller);
  }

  void _onLoadFailed() {
    _controller.dispose();
    FullScreenAdLoading.instance.removeLoading();
    onFailed?.call();
  }

  void dispose() {
    if (_initialized) _controller.dispose();
    _appLifecycleListener?.dispose();
  }
}
