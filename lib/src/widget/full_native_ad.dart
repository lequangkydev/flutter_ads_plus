import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_ads_plus/flutter_ads_plus.dart';

import '../utils/logger.dart';
import '../utils/my_completer.dart';

/// Single-slot overlay state for the native-format ad shown on top of
/// the app-open-resume ad. Only one can be in flight at a time;
/// re-entry replaces the existing overlay.
///
/// State overlay 1 slot cho native-format ad phủ lên app-open-resume.
/// Mỗi lúc chỉ có 1 — gọi lại sẽ thay overlay cũ.
OverlayEntry? _overlayEntry;

/// Insert a fullscreen native ad as an [OverlayEntry] above the current
/// route. Used by [AppLifecycleReactor] when
/// [MyAds.enableNativeFullResume] is on. Returns when the user closes
/// the ad (or load fails / context is unavailable).
///
/// Chèn native ad full-màn dưới dạng [OverlayEntry] đè lên route hiện
/// tại. Được [AppLifecycleReactor] dùng khi [MyAds.enableNativeFullResume]
/// bật. Trả về khi user đóng ad (hoặc load fail / không có context).
Future<void> showFullNativeAd({
  required NativeAdController controller,
  bool showLoading = true,
}) async {
  final MyCompleter<void> completer = MyCompleter();
  _removeOverlay();
  _overlayEntry = OverlayEntry(
    builder: (context) {
      return FullNativeAd(
        controller: controller,
        showLoading: showLoading,
        onClose: () {
          completer.complete();
        },
      );
    },
  );
  if (MyAds.instance.navigatorKey.currentContext == null) {
    logger.e("Navigator context is null, cannot show ad.");
    completer.complete();
    return completer.future;
  }
  try {
    Overlay.of(MyAds.instance.navigatorKey.currentContext!)
        .insert(_overlayEntry!);
  } on Exception catch (e) {
    logger.e(e);
    completer.complete();
  }
  return completer.future;
}

void _removeOverlay() {
  try {
    _overlayEntry?.remove();
    _overlayEntry?.dispose();
    _overlayEntry = null;
  } on Exception catch (e) {
    logger.e(e);
  }
}

class FullNativeAd extends StatefulWidget {
  const FullNativeAd({
    super.key,
    required this.onClose,
    required this.controller,
    required this.showLoading,
  });

  final VoidCallback onClose;
  final NativeAdController controller;
  final bool showLoading;

  @override
  State<FullNativeAd> createState() => _FullNativeAdState();
}

class _FullNativeAdState extends State<FullNativeAd>
    with AutomaticKeepAliveClientMixin {
  NativeAdController? controller;
  final ValueNotifier<int> _countDownNotifier = ValueNotifier<int>(1);
  Timer? timer;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    // Suspend resume-show while the native fullscreen is up so the
    // reactor doesn't try to layer another app-open on top.
    // Tạm ngắt resume-show trong lúc native fullscreen đang hiện để
    // reactor không cố phủ thêm 1 app-open lên trên.
    MyAds.instance.appLifecycleReactor?.setShouldShow(false);

    controller = widget.controller;
    if (controller == null || controller!.status.isLoadFailed) {
      closeAd();
    }
    controller
      ?..onAdFailedToLoad = (_, __) {
        closeAd();
      }
      // The close button is initially the countdown number; once the
      // ad has impression the countdown ticks down and reveals the
      // close icon when it reaches 0.
      // Nút close ban đầu là số đếm ngược; khi ad có impression thì đếm
      // ngược giảm dần và hiện icon close khi về 0.
      ..onAdImpression = (_) {
        timer = Timer.periodic(const Duration(seconds: 1), (timer) {
          if (_countDownNotifier.value > 0) {
            _countDownNotifier.value = _countDownNotifier.value - 1;
          } else {
            timer.cancel();
          }
        });
      };
  }

  void closeAd() {
    _removeOverlay();
    widget.onClose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (controller == null) {
      return const SizedBox();
    }
    return DecoratedBox(
      decoration: const BoxDecoration(color: Colors.black),
      child: MyNativeAd.control(
        height: MediaQuery.of(context).size.height,
        controller: controller,
        hasCloseButton: true,
        customCloseButton: _buildCloseButton(controller!.factoryId),
        loadingWidget: widget.showLoading
            ? Container(
                width: MediaQuery.of(context).size.width,
                height: MediaQuery.of(context).size.height,
                color: Colors.white,
                child: FullScreenAdLoading.instance.lottieLoading(),
              )
            : const SizedBox(),
      ),
    );
  }

  Positioned? _buildCloseButton(String factoryId) {
    return Positioned(
      top: 50,
      right: 14,
      child: ValueListenableBuilder(
        valueListenable: _countDownNotifier,
        builder: (context, state, child) {
          return _CloseButton(
            count: state,
            onTap: () {
              closeAd();
            },
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    if (controller != null) {
      // Dispose the just-shown controller and stage a fresh clone
      // (same config, no loaded ad yet) on the reactor for the next
      // resume cycle.
      // Dispose controller vừa show và đặt 1 clone mới (cùng config,
      // chưa load ad) lên reactor cho cycle resume tiếp theo.
      widget.controller.dispose();
      MyAds.instance.appLifecycleReactor?.nativeFullAdController =
          widget.controller.copyWith();
    }
    MyAds.instance.appLifecycleReactor?.setShouldShow(true);

    timer?.cancel();
    _countDownNotifier.dispose();
    super.dispose();
  }
}

class _CloseButton extends StatelessWidget {
  const _CloseButton({required this.onTap, required this.count});

  final VoidCallback onTap;
  final int count;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Stack(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xff737373),
              ),
            ),
            Positioned.fill(
              child: count > 0
                  ? Center(
                      child: Text(
                        count.toString(),
                        style:
                            const TextStyle(fontSize: 15, color: Colors.white),
                      ),
                    )
                  : const Icon(
                      Icons.close,
                      color: Color(0xFFDADADA),
                      size: 15,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
