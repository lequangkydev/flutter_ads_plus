import 'dart:io';
import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:video_player/video_player.dart';

import '../../model/loading_model.dart';
import '../../utils/logger.dart';

/// Singleton owning the fullscreen loading overlay used while a
/// fullscreen ad is loading + transitioning. Configure once at
/// [MyAds.initialize] via [FullScreenLoadingConfig].
///
/// Singleton quản lý overlay loading toàn màn trong lúc fullscreen ad
/// load + chuyển cảnh. Cấu hình 1 lần ở [MyAds.initialize] qua
/// [FullScreenLoadingConfig].
///
/// Two modes via [showLoading]:
/// - `enableLoading: true` (default): show the configured loading
///   widget (Lottie / video / custom) on top of the background color.
/// - `enableLoading: false`: keep the overlay (blocking taps) but hide
///   the loading widget — used right after the ad shows so the page
///   underneath isn't visible during the SDK's transition frames.
///
/// Hai mode qua [showLoading]:
/// - `enableLoading: true` (mặc định): hiển thị loading widget đã cấu
///   hình (Lottie / video / custom) trên background color.
/// - `enableLoading: false`: vẫn giữ overlay (chặn tap) nhưng ẩn loading
///   widget — dùng ngay sau khi ad show để không nhìn thấy trang dưới
///   trong các frame transition của SDK.
class FullScreenAdLoading {
  FullScreenAdLoading._();

  static final instance = FullScreenAdLoading._();
  FullScreenLoadingConfig loadingConfig = LottieLoadingConfig();
  final List<Future<LottieComposition>> _lottieCompositions = [];

  OverlayEntry? overlayEntry;
  final _loadingNotifier = ValueNotifier(true);

  /// Used when [loadingConfig] is a [VideoLoadingConfig]. Initialized
  /// once at [preloadAnimations] time.
  ///
  /// Dùng khi [loadingConfig] là [VideoLoadingConfig]. Init 1 lần ở
  /// [preloadAnimations].
  VideoPlayerController? _videoController;

  Future<void> preloadAnimations(
      FullScreenLoadingConfig? fullScreenLoadingConfig) async {
    if (fullScreenLoadingConfig != null) {
      loadingConfig = fullScreenLoadingConfig;
    }
    if (fullScreenLoadingConfig is VideoLoadingConfig) {
      await _preloadVideo();
    } else if (fullScreenLoadingConfig is LottieLoadingConfig ||
        fullScreenLoadingConfig == null) {
      await _preloadLottie();
    }
  }

  Future<void> _preloadVideo() async {
    final config = loadingConfig as VideoLoadingConfig;
    try {
      _videoController = switch (config.type) {
        VideoType.asset => VideoPlayerController.asset(config.path),
        VideoType.network =>
          VideoPlayerController.networkUrl(Uri.parse(config.path)),
        VideoType.file => VideoPlayerController.file(File(config.path)),
      };
      await _videoController!.initialize();
    } on Exception catch (e) {
      logger.e(e);
    }
  }

  Future<void> _preloadLottie() async {
    if (_lottieCompositions.isNotEmpty) return;
    final lottieConfig = loadingConfig as LottieLoadingConfig?;
    if (lottieConfig?.lottiePaths != null &&
        lottieConfig!.lottiePaths!.isNotEmpty) {
      // Sử dụng các lottie được truyền vào
      for (String path in lottieConfig.lottiePaths!) {
        _lottieCompositions.add(AssetLottie(path).load());
      }
    } else {
      // Sử dụng các lottie mặc định
      for (int index in Iterable.generate(12)) {
        _lottieCompositions.add(AssetLottie(
                'assets/lottie/waiting${index + 1}.json',
                package: 'flutter_ads_plus')
            .load());
      }
    }
  }

  void hideLoadingWidget() {
    _loadingNotifier.value = false;
  }

  void removeLoading() {
    try {
      if (overlayEntry?.mounted ?? false) {
        overlayEntry?.remove();
        overlayEntry?.dispose();
        overlayEntry = null;
      }
    } on Exception catch (e) {
      logger.e(e);
    }
  }

  /// Insert the loading overlay into the navigator's [Overlay]. Replaces
  /// any previous overlay first.
  ///
  /// Chèn overlay loading vào [Overlay] của navigator. Thay overlay cũ
  /// trước nếu có.
  ///
  /// [enableLoading] = `false` keeps the overlay but hides the loading
  /// widget (used as a transparent tap-blocker once the ad has
  /// actually shown).
  ///
  /// [enableLoading] = `false` giữ overlay nhưng ẩn loading widget (dùng
  /// như shield chặn tap sau khi ad đã thực sự show).
  void showLoading(
    BuildContext context, {
    bool enableLoading = true,
  }) {
    removeLoading();
    if (enableLoading) {
      _loadingNotifier.value = true;
    } else {
      _loadingNotifier.value = false;
    }

    Widget loadingWidget;

    if (loadingConfig is VideoLoadingConfig && _videoController != null) {
      loadingWidget = videoLoading();
    } else if (loadingConfig is WidgetLoadingConfig) {
      loadingWidget = (loadingConfig as WidgetLoadingConfig).loadingWidget ??
          const Center(child: CupertinoActivityIndicator());
    } else {
      loadingWidget = lottieLoading();
    }
    overlayEntry = OverlayEntry(
      builder: (context) {
        return ValueListenableBuilder(
          valueListenable: _loadingNotifier,
          builder: (context, showLoading, child) {
            return Scaffold(
              backgroundColor:
                  showLoading ? loadingConfig.backgroundColor : Colors.black,
              body: showLoading ? loadingWidget : null,
            );
          },
        );
      },
    );
    try {
      Overlay.of(context).insert(overlayEntry!);
    } on Exception catch (e) {
      logger.e(e);
    }
  }

  Widget videoLoading() {
    if (_videoController == null || !_videoController!.value.isInitialized) {
      return const Center(child: CupertinoActivityIndicator());
    }
    _videoController!.seekTo(Duration.zero);
    _videoController!.play();
    return ColoredBox(
      color: (loadingConfig as VideoLoadingConfig).backgroundColor,
      child: Center(
        child: AspectRatio(
          aspectRatio: _videoController!.value.aspectRatio,
          child: VideoPlayer(_videoController!),
        ),
      ),
    );
  }

  Widget lottieLoading() {
    if (_lottieCompositions.isEmpty) {
      return const Center(child: CupertinoActivityIndicator());
    }
    Random random = Random();
    int randomNumber = random.nextInt(_lottieCompositions.length);
    final com = _lottieCompositions[randomNumber];
    final config = loadingConfig as LottieLoadingConfig?;
    final lottie = FutureBuilder<LottieComposition>(
      future: com,
      builder: (context, snapshot) {
        var composition = snapshot.data;
        final size = config?.size ?? 230.0;
        if (composition != null) {
          return Lottie(
            composition: composition,
            width: size,
            height: size,
            fit: BoxFit.fitWidth,
          );
        } else {
          return SizedBox.square(
            dimension: size,
            child: const Center(child: CupertinoActivityIndicator()),
          );
        }
      },
    );
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: Center(child: lottie),
        ),
        if (config?.showLoadingText ?? true)
          Text(
            config?.loadingText ?? 'Ad is loading...',
            style: config?.loadingTextStyle ??
                const TextStyle(
                  color: Colors.black54,
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                ),
            textAlign: TextAlign.center,
          ),
      ],
    );
  }
}
