import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_ads_plus/flutter_ads_plus.dart';

import 'home_screen.dart';

const _inlineAdKey = 'app_open_inline';

/// Three ways to show an App Open ad:
/// 1. Preload via controller pre-loaded by [HomeScreen].
/// 2. Inline load + show (no controller).
/// 3. (Observed via the status box) the native PreloadV2 events for
///    app-open ads (this is the path used by `MyAds.showSplashAd` /
///    `showAppOpenAd` when a native preloaded ad is available).
///
/// 3 cách show App Open ad:
/// 1. Preload qua controller [HomeScreen] đã preload.
/// 2. Load + show inline (không controller).
/// 3. (Quan sát qua status box) event native PreloadV2 cho app-open
///    (đường này được `MyAds.showSplashAd` / `showAppOpenAd` dùng khi
///    có ad preload sẵn ở native).
class ResumeScreen extends StatefulWidget {
  const ResumeScreen({
    super.key,
    required this.adId,
    required this.preloaded,
  });

  final String adId;
  final AppOpenAdController? preloaded;

  @override
  State<ResumeScreen> createState() => _ResumeScreenState();
}

class _ResumeScreenState extends State<ResumeScreen> {
  String _status = 'Idle / Chờ';
  StreamSubscription<BasePreloadEvent>? _nativeEventsSub;

  @override
  void initState() {
    super.initState();
    _nativeEventsSub = NativeAppOpenPreloadUtil.events.listen(_onNativeEvent);
  }

  void _onNativeEvent(BasePreloadEvent event) {
    if (!mounted) return;
    setState(() {
      if (event is AdPreloadedEvent) {
        _status = 'Native preloaded: ${event.adUnitId}';
      } else if (event is AdsExhaustedEvent) {
        _status = 'Native buffer exhausted — reloading...';
      } else if (event is AdFailedToPreloadEvent) {
        _status = 'Native preload failed: ${event.message}';
      } else if (event is AdShowedEvent) {
        _status = 'Ad on screen';
      } else if (event is AdDismissedEvent) {
        _status = 'Ad dismissed';
      } else if (event is AdFailedToShowEvent) {
        _status = 'Show failed: ${event.message}';
      } else if (event is AdPaidEvent) {
        _status =
            'Paid: ${event.value.toStringAsFixed(4)} ${event.currencyCode}';
      }
    });
  }

  Future<void> _showWithController() async {
    await MyAds.instance.showAppOpenAd(
      context,
      adId: widget.adId,
      controller: widget.preloaded,
      adKey: kAppOpenKey,
      immersiveModeEnabled: false,
      onShowed: () => setState(() => _status = 'Preloaded ad shown'),
      adDismissed: () =>
          setState(() => _status = 'Preloaded ad dismissed'),
      onFailed: () => setState(() => _status = 'Preloaded ad failed'),
    );
  }

  Future<void> _showInline() async {
    await MyAds.instance.showAppOpenAd(
      context,
      adId: widget.adId,
      adKey: _inlineAdKey,
      immersiveModeEnabled: false,
      onShowed: () => setState(() => _status = 'Inline ad shown'),
      adDismissed: () => setState(() => _status = 'Inline ad dismissed'),
      onFailed: () => setState(() => _status = 'Inline ad failed'),
    );
  }

  @override
  void dispose() {
    _nativeEventsSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blueGrey,
      appBar: AppBar(
        title: const Text('App Open Demo'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.black45,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    const Text(
                      'Status / Trạng thái',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _status,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Background the app and resume to trigger the auto '
                'app-open-resume ad.\n\n'
                'Background app rồi quay lại để trigger app-open-resume.',
                style: TextStyle(color: Colors.white70, fontSize: 12),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              _Btn(
                '1. Preload + show (controller)',
                _showWithController,
                Colors.teal,
              ),
              const SizedBox(height: 8),
              _Btn(
                '2. Load + show inline (no controller)',
                _showInline,
                Colors.teal,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Btn extends StatelessWidget {
  const _Btn(this.label, this.onTap, this.color);
  final String label;
  final VoidCallback onTap;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 15, color: Colors.white),
      ),
    );
  }
}
