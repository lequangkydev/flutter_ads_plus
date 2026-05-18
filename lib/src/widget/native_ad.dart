import 'package:flutter/material.dart';
import 'package:flutter_ads_plus/flutter_ads_plus.dart';

import 'loading/loading_ad.dart';

/// Native ad widget. Use the unnamed constructor to let the widget
/// build a fresh [NativeAdController], or [MyNativeAd.control] when you
/// own the controller.
///
/// Widget native ad. Dùng constructor không tên để widget tự build
/// [NativeAdController], hoặc [MyNativeAd.control] khi bạn tự quản
/// controller.
///
/// For impression-triggered swap-in flows (load N+1 while showing N),
/// use [MyNativeAd2] together with
/// [NativeAdController.loadOnImpression].
///
/// Cho flow swap-in trigger bởi impression (load N+1 trong khi đang
/// show N), dùng [MyNativeAd2] kết hợp
/// [NativeAdController.loadOnImpression].
class MyNativeAd extends StatefulWidget {
  final String? factoryId;
  final String? adId;
  final double height;
  final Widget? loadingWidget;
  final NativeAdController? controller;
  final NativeAdOptions? nativeAdOptions;
  final Map<String, Object>? customOptions;
  final void Function(Ad ad)? onLoaded;
  final void Function()? onFailed;
  final bool maintainSizeOnError;
  final bool hasCloseButton;
  final bool showLoading;
  final bool? reloadOnClicked;
  final Positioned? customCloseButton;
  final String? adKey;

  const MyNativeAd({
    super.key,
    this.adId,
    this.reloadOnClicked,
    this.factoryId,
    required this.height,
    this.loadingWidget,
    this.onLoaded,
    this.nativeAdOptions,
    this.customOptions,
    this.maintainSizeOnError = false,
    this.hasCloseButton = false,
    this.showLoading = true,
    this.customCloseButton,
    this.adKey,
    this.onFailed,
  }) : controller = null;

  const MyNativeAd.control({
    super.key,
    required this.controller,
    required this.height,
    this.loadingWidget,
    this.onLoaded,
    this.maintainSizeOnError = false,
    this.hasCloseButton = false,
    this.customCloseButton,
    this.showLoading = true,
    this.adKey,
    this.onFailed,
  })  : adId = null,
        factoryId = null,
        nativeAdOptions = null,
        customOptions = null,
        reloadOnClicked = null;

  @override
  State<MyNativeAd> createState() => _MyNativeAdState();
}

class _MyNativeAdState extends State<MyNativeAd> {
  NativeAdController? controller;
  bool visible = true;

  @override
  void didUpdateWidget(covariant MyNativeAd oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller != null) {
      if (oldWidget.controller?.controllerId !=
          widget.controller!.controllerId) {
        controller = widget.controller!;
      }
    } else {
      if (oldWidget.adId != widget.adId) {
        controller?.dispose();
        controller = NativeAdController(
          adId: widget.adId!,
          factoryId: widget.factoryId!,
          reloadOnClicked: widget.reloadOnClicked,
          customOptions: widget.customOptions,
          nativeAdOptions: widget.nativeAdOptions,
          adKey: widget.adKey,
        )..load();
      }
    }
  }

  @override
  void initState() {
    super.initState();
    initAd();
  }

  void initAd() async {
    if (widget.controller == null) {
      controller = NativeAdController(
        adId: widget.adId!,
        factoryId: widget.factoryId!,
        nativeAdOptions: widget.nativeAdOptions,
        customOptions: widget.customOptions,
        adKey: widget.adKey,
        reloadOnClicked: widget.reloadOnClicked,
      );
      controller?.load();
    } else {
      controller = widget.controller!;
    }
    if (!MyAds.instance.hasInternet) {
      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!visible || controller == null) {
      return const SizedBox();
    }
    return StreamBuilder(
      stream: controller!.stream,
      initialData: controller!.status,
      builder: (context, snapshot) {
        final status = snapshot.data;
        final ad = controller!.ad;
        // ẩn quảng cáo khi load lỗi
        if (status?.isLoadFailed ?? false) {
          widget.onFailed?.call();
          return SizedBox(
            height: widget.maintainSizeOnError ? widget.height : 0,
          );
        }
        if (status == null ||
            !status.isShowOnScreen ||
            ad?.responseInfo?.responseId == null) {
          if (!widget.showLoading) {
            return const SizedBox();
          }
          return SizedBox(
            height: widget.height,
            child: widget.loadingWidget ?? const MyLoadingAd(),
          );
        }
        if (status.isLoaded) {
          widget.onLoaded?.call(ad!);
        }
        return Stack(
          children: [
            SizedBox(
              height: widget.height,
              child: StatefulBuilder(
                builder: (context, setState) => AdWidget(ad: ad!),
              ),
            ),
            if (widget.hasCloseButton)
              widget.customCloseButton ??
                  Positioned(
                    top: 20,
                    right: 8,
                    child: CloseAdButton(
                      onTap: () {
                        setState(() {
                          visible = false;
                        });
                      },
                    ),
                  ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      controller?.dispose();
    }
    super.dispose();
  }
}
