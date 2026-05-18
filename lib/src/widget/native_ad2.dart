import 'package:flutter/material.dart';
import 'package:flutter_ads_plus/flutter_ads_plus.dart';

import 'loading/loading_ad.dart';

/// Variant of [MyNativeAd] that pairs with
/// [NativeAdController.loadOnImpression]: the current ad keeps rendering
/// while a *next* ad loads in the background, and the controller's
/// [updateAd] swaps it in with no flicker.
///
/// Biến thể của [MyNativeAd] dùng kèm [NativeAdController.loadOnImpression]:
/// ad hiện tại tiếp tục render trong khi ad *kế tiếp* load nền, rồi
/// controller gọi [updateAd] để swap không flicker.
class MyNativeAd2 extends StatefulWidget {
  final double height;
  final Widget? loadingWidget;
  final NativeAdController? controller;
  final void Function(Ad ad)? onLoaded;
  final bool maintainSizeOnError;
  final bool hasCloseButton;
  final Positioned? customCloseButton;
  final bool showLoading;

  const MyNativeAd2({
    super.key,
    this.controller,
    required this.height,
    this.loadingWidget,
    this.onLoaded,
    this.maintainSizeOnError = false,
    this.hasCloseButton = false,
    this.customCloseButton,
    this.showLoading = true,
  });

  @override
  State<MyNativeAd2> createState() => _MyNativeAd2State();
}

class _MyNativeAd2State extends State<MyNativeAd2> {
  late NativeAdController controller;
  bool visible = true;

  @override
  void didUpdateWidget(covariant MyNativeAd2 oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller?.controllerId != widget.controller!.controllerId) {
      controller = widget.controller!;
    }
  }

  @override
  void initState() {
    super.initState();
    controller = widget.controller!;
  }

  @override
  Widget build(BuildContext context) {
    if (!visible) {
      return const SizedBox();
    }
    return StreamBuilder(
      stream: controller.stream,
      initialData: controller.status,
      builder: (context, snapshot) {
        final status = snapshot.data;
        final ad = controller.ad;
        if (!controller.loadSecondAd) {
          if (status == null || status.isLoading) {
            return buildLoading();
          }
          if (status.isLoadFailed) {
            return SizedBox(
              height: widget.maintainSizeOnError ? widget.height : 0,
            );
          }
          if (ad?.responseInfo?.responseId == null || !status.isShowOnScreen) {
            return buildLoading();
          }
          if (status.isLoaded) {
            widget.onLoaded?.call(ad!);
          }
        }
        if (ad == null) {
          return buildLoading();
        }
        return Stack(
          children: [
            SizedBox(
              height: widget.height,
              child: StatefulBuilder(
                builder: (context, setState) => AdWidget(
                  ad: ad,
                  key: ValueKey(ad.responseInfo?.responseId),
                ),
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

  SizedBox buildLoading() {
    if (!widget.showLoading) {
      return const SizedBox();
    }
    return SizedBox(
      height: widget.height,
      child: widget.loadingWidget ?? const MyLoadingAd(),
    );
  }
}
