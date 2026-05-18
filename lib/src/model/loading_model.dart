import 'package:flutter/material.dart';

/// Tag for which kind of full-screen loading overlay is configured.
/// Đánh dấu loại overlay loading toàn màn đang được cấu hình.
enum LoadingType {
  video,
  lottie,
  widget,
}

/// Base class for the full-screen loading overlay shown while a
/// fullscreen ad is being loaded. Default = [LottieLoadingConfig] with
/// the 12 bundled assets.
///
/// Lớp cơ sở cho overlay loading toàn màn khi đang load fullscreen ad.
/// Mặc định = [LottieLoadingConfig] với 12 lottie kèm theo package.
class FullScreenLoadingConfig {
  final Color backgroundColor;

  FullScreenLoadingConfig({this.backgroundColor = Colors.white});
}

// ========== Video Config ===========

/// Use a single video as the loading animation. The video is initialized
/// once at [MyAds.initialize] and looped from start on every show.
///
/// Dùng 1 video làm loading animation. Video init 1 lần lúc
/// [MyAds.initialize] và loop từ đầu mỗi lần show.
class VideoLoadingConfig extends FullScreenLoadingConfig {
  final String path;
  final VideoType type;

  VideoLoadingConfig({
    required this.path,
    this.type = VideoType.asset,
    super.backgroundColor = Colors.black,
  });
}

enum VideoType {
  asset,
  network,
  file,
}

// ========== Lottie Config ===========

/// Use Lottie animations as the loading widget. Pass [lottiePaths] to
/// override the default 12-asset rotation; the runner picks one at
/// random for each show.
///
/// Dùng Lottie làm loading widget. Truyền [lottiePaths] để override bộ
/// 12 asset mặc định; runner chọn random 1 cái mỗi lần show.
class LottieLoadingConfig extends FullScreenLoadingConfig {
  final bool showLoadingText;
  final String loadingText;
  final double size;
  final TextStyle? loadingTextStyle;

  final List<String>? lottiePaths;

  LottieLoadingConfig({
    this.showLoadingText = true,
    this.loadingText = 'Ad is loading...',
    this.lottiePaths,
    super.backgroundColor,
    this.size = 230,
    this.loadingTextStyle,
  });
}

// =========== Widget Config ===========

/// Use an arbitrary widget as the loading content (e.g. a Lottie not
/// included here, a custom spinner, or a marketing graphic).
///
/// Dùng widget bất kỳ làm loading content (vd. Lottie khác, spinner tự
/// custom, hoặc graphic marketing).
class WidgetLoadingConfig extends FullScreenLoadingConfig {
  final Widget? loadingWidget;

  WidgetLoadingConfig({
    this.loadingWidget,
    super.backgroundColor,
  });
}
