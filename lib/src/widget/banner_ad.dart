import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_ads_plus/flutter_ads_plus.dart';

/// Banner ad widget. Use the unnamed constructor to let the widget
/// build its own [BannerAdController], or use [MyBannerAd.control] to
/// pass a pre-built controller you own and manage.
///
/// Widget banner ad. Dùng constructor không tên để widget tự build
/// [BannerAdController], hoặc dùng [MyBannerAd.control] để truyền vào
/// controller bạn tự quản lý.
///
/// When [listenAppState] is `true`, the widget reloads the banner after
/// the app-open-resume ad dismisses, so an old impression isn't shown
/// to a returning user. Collapsible banners are also disposed on
/// `paused` to avoid the SDK retaining their content while in
/// background.
///
/// Khi [listenAppState] = `true`, widget reload banner sau khi app-open-
/// resume dismiss, để không show impression cũ cho user vừa trở lại.
/// Collapsible banner cũng dispose lúc `paused` để SDK không giữ content
/// khi app trong background.
class MyBannerAd extends StatefulWidget {
  final AdSize? adSize;
  final String? adId;
  final bool? isCollapsible;
  final bool listenAppState;
  final Widget? loadingWidget;
  final BannerAdController? controller;
  final Border? borderBanner;
  final Color? backgroundColor;
  final Color? shimmerBaseColor;
  final Color? shimmerHighlightColor;
  final String? adKey;
  final bool showLoading;

  const MyBannerAd({
    super.key,
    this.adId,
    this.adSize,
    this.isCollapsible,
    this.loadingWidget,
    this.borderBanner,
    this.backgroundColor,
    this.shimmerBaseColor,
    this.shimmerHighlightColor,
    this.listenAppState = true,
    this.adKey,
    this.showLoading = true,
  }) : controller = null;

  /// Use this constructor when you own the controller (e.g. preloading
  /// elsewhere or reusing one across screens).
  ///
  /// Dùng constructor này khi bạn tự quản controller (vd. preload chỗ
  /// khác hoặc tái dùng giữa nhiều screen).
  const MyBannerAd.control({
    super.key,
    this.controller,
    this.loadingWidget,
    this.borderBanner,
    this.backgroundColor,
    this.shimmerBaseColor,
    this.shimmerHighlightColor,
    this.listenAppState = true,
    this.adKey,
    this.showLoading = true,
  })  : adId = null,
        isCollapsible = null,
        adSize = null;

  @override
  State<MyBannerAd> createState() => _MyBannerAdState();
}

class _MyBannerAdState extends State<MyBannerAd> with WidgetsBindingObserver {
  late BannerAdController controller;
  AdStatus statusBeforeHideApp = AdStatus.init;
  StreamSubscription<AdInformation>? _eventsSub;

  bool get isCollapsible {
    bool isCollapsible = false;
    if (widget.controller != null) {
      isCollapsible = controller.isCollapsible;
    } else {
      isCollapsible = widget.isCollapsible ?? false;
    }
    return isCollapsible;
  }

  @override
  void initState() {
    WidgetsBinding.instance.addObserver(this);
    _initAd();
    if (widget.listenAppState) {
      // When the app-open-resume ad dismisses, the user is back on the
      // host screen. Reload the banner so they don't see a stale ad
      // from before the background trip. [statusBeforeHideApp] guards
      // against reloading when nothing was disposed.
      // Khi app-open-resume ad dismiss, user trở về host screen. Reload
      // banner để không thấy ad cũ từ trước khi background. Cờ
      // [statusBeforeHideApp] tránh reload khi không có gì bị dispose.
      _eventsSub = MyAds.instance.events.listen((event) {
        final canLoadBanner = !statusBeforeHideApp.isInit;
        if (event.type == AdType.appOpen &&
            event.status.isDismiss &&
            canLoadBanner) {
          controller.load();
          statusBeforeHideApp = AdStatus.loading;
        }
      });
    }

    super.initState();
  }

  @override
  void didUpdateWidget(covariant MyBannerAd oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller != null) {
      if (oldWidget.controller?.controllerId !=
          widget.controller!.controllerId) {
        controller = widget.controller!;
      }
    } else {
      if (oldWidget.adId != widget.adId) {
        controller.dispose();
        controller = BannerAdController(
          adId: widget.adId!,
          adSize: widget.adSize,
          isCollapsible: widget.isCollapsible ?? false,
          adKey: widget.adKey,
        )..load();
      }
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (!widget.listenAppState) {
      return;
    }
    if (MyAds.instance.appLifecycleReactor?.isExcludeScreen ?? false) {
      return;
    }
    if (!(MyAds.instance.appLifecycleReactor?.shouldShow ?? false)) {
      return;
    }
    if (MyAds.instance.isFullscreenAdShowing) {
      return;
    }
    if (!isCollapsible) {
      return;
    }
    // Only collapsible banners are disposed on pause — the SDK can
    // keep ordinary banners loaded across background trips, but
    // collapsible state otherwise persists incorrectly.
    // Chỉ collapsible banner mới dispose lúc pause — banner thường có
    // thể giữ load qua background, còn collapsible nếu không dispose
    // sẽ giữ state sai.
    if (state == AppLifecycleState.paused) {
      statusBeforeHideApp = controller.status;
      controller.disposeAd();
    }
  }

  @override
  Widget build(BuildContext context) {
    return buildBannerAd();
  }

  Widget buildBannerAd() {
    return StreamBuilder(
      stream: controller.stream,
      initialData: controller.status,
      builder: (context, snapshot) {
        final status = snapshot.data!;
        final ad = controller.ad;
        if (status.isLoading) {
          return _buildLoading();
        }
        if (status.isLoadFailed) {
          return const SizedBox();
        }
        if (ad?.responseInfo?.responseId == null || !status.isShowOnScreen) {
          return _buildLoading();
        }

        return Container(
          height: controller.adSize?.height.toDouble(),
          width: controller.adSize?.width.toDouble(),
          decoration: BoxDecoration(
            color: widget.backgroundColor ?? Colors.white,
            border: widget.borderBanner ??
                const Border(
                  top: BorderSide(color: Colors.black, width: 2),
                  bottom: BorderSide(color: Colors.black, width: 2),
                ),
          ),
          child: StatefulBuilder(
            builder: (context, setState) => AdWidget(ad: ad!),
          ),
        );
      },
    );
  }

  Widget _buildLoading() {
    if (!widget.showLoading) {
      return const SizedBox();
    }
    if (MyAds.instance.hasInternet) {
      if (widget.loadingWidget != null) {
        return widget.loadingWidget!;
      }
      return BannerAdLoading(
        height: controller.adSize?.height.toDouble() ?? 60,
        backgroundColor: widget.backgroundColor,
        shimmerBaseColor: widget.shimmerBaseColor,
        shimmerHighlightColor: widget.shimmerHighlightColor,
      );
    }
    return const SizedBox();
  }

  Future<void> _initAd() async {
    if (widget.controller == null) {
      controller = BannerAdController(
        adId: widget.adId!,
        adSize: widget.adSize,
        isCollapsible: widget.isCollapsible ?? false,
        adKey: widget.adKey,
      );
      controller.load();
    } else {
      controller = widget.controller!;
    }
  }

  @override
  void dispose() {
    _eventsSub?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    if (widget.controller == null) {
      controller.dispose();
    }
    super.dispose();
  }
}
