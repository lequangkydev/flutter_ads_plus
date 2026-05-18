import 'package:flutter/material.dart';
import 'package:flutter_ads_plus/flutter_ads_plus.dart';

import 'home_screen.dart';

const _inlineAdKey = 'inter_inline';

/// Two-variant interstitial demo.
///
/// 1. **Preload** — uses the controller pre-loaded by [HomeScreen]; the
///    first tap shows the ad with no loading overlay because it's
///    already loaded. HomeScreen recreates the controller on dismiss so
///    repeated entries to this screen also get a ready ad.
/// 2. **Inline** — calls [MyAds.showInterstitialAd] with `adId` only;
///    the runner builds a controller, loads it, and the user sees the
///    full-screen loading overlay until the ad is ready.
/// 3. **Splash** — uses [MyAds.showSplashAd] which prefers the native
///    PreloadV2 buffer when populated.
///
/// Demo interstitial 2 (+1) biến thể.
///
/// 1. **Preload** — dùng controller [HomeScreen] đã preload; lần tap
///    đầu show ad không thấy loading vì đã load xong. HomeScreen
///    recreate controller khi dismiss để lần sau cũng có ad sẵn.
/// 2. **Inline** — gọi [MyAds.showInterstitialAd] chỉ với `adId`;
///    runner tự build controller, load, user thấy overlay loading toàn
///    màn đến khi ad sẵn sàng.
/// 3. **Splash** — [MyAds.showSplashAd] ưu tiên buffer native PreloadV2
///    nếu có sẵn.
class InterScreen extends StatelessWidget {
  const InterScreen({
    super.key,
    required this.adId,
    required this.preloaded,
  });

  final String adId;

  /// Pre-loaded controller from [HomeScreen]. Disposed by the runner
  /// after the show; HomeScreen rebuilds it via its dismiss listener.
  /// Controller preload từ [HomeScreen]. Runner sẽ dispose sau show;
  /// HomeScreen rebuild qua dismiss listener của nó.
  final InterstitialAdController? preloaded;

  void _goToNextScreen(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const Scaffold(backgroundColor: Colors.red),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blueGrey,
      appBar: AppBar(
        title: const Text('Inter Demo'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FilledButton(
                onPressed: () async {
                  await MyAds.instance.showInterstitialAd(
                    context,
                    adId: adId,
                    controller: preloaded,
                    adKey: kInterKey,
                    forceShow: true,
                    onShowed: () => _goToNextScreen(context),
                    onFailed: () => _goToNextScreen(context),
                    onNoInternet: () => _goToNextScreen(context),
                    adDismissed: () =>
                        debugPrint('Preloaded inter dismissed'),
                  );
                },
                child: const Text('1. Preload + show (controller)'),
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () async {
                  // Variant 2 — no controller. The runner builds one,
                  // calls load(), shows the loading overlay until the
                  // ad is ready, then shows the ad.
                  // Biến thể 2 — không controller. Runner tự build,
                  // load(), hiển thị overlay loading đến khi ad sẵn,
                  // rồi show.
                  await MyAds.instance.showInterstitialAd(
                    context,
                    adId: adId,
                    adKey: _inlineAdKey,
                    forceShow: true,
                    onShowed: () => _goToNextScreen(context),
                    onFailed: () => _goToNextScreen(context),
                    onNoInternet: () => _goToNextScreen(context),
                    adDismissed: () => debugPrint('Inline inter dismissed'),
                  );
                },
                child: const Text('2. Load + show inline (no controller)'),
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () async {
                  await MyAds.instance.showSplashAd(
                    context,
                    adId: adId,
                    useInterAd: true,
                    onShowed: () => _goToNextScreen(context),
                    onFailed: () => _goToNextScreen(context),
                    onNoInternet: () => _goToNextScreen(context),
                    adDismissed: () => debugPrint('Splash inter dismissed'),
                  );
                },
                child: const Text('3. Splash (native preload + fallback)'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
