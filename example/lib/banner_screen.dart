import 'package:flutter/material.dart';
import 'package:flutter_ads_plus/flutter_ads_plus.dart';

import 'ad_loading.dart';

const _adId = 'ca-app-pub-3940256099942544/8388050270';
const _inlineAdKey = 'banner_inline';

/// Two-variant banner demo.
///
/// 1. **Preload** — a [BannerAdController] was created and `load()`ed
///    on the *previous* screen (HomeScreen). Passed in via [preloaded].
///    The ad is already loaded by the time this screen mounts, so the
///    `MyBannerAd.control` renders the ad with no visible loading state.
/// 2. **Inline** — the widget builds its own controller from `adId` on
///    mount, so the user sees the loading placeholder for ~1-2s while
///    the SDK fetches an ad.
///
/// Demo banner 2 biến thể.
///
/// 1. **Preload** — [BannerAdController] đã được tạo và `load()` từ
///    screen *trước* (HomeScreen). Truyền vào qua [preloaded]. Ad đã
///    load xong khi screen này mount, nên `MyBannerAd.control` render
///    ad mà không thấy loading.
/// 2. **Inline** — widget tự build controller từ `adId` lúc mount, user
///    sẽ thấy loading placeholder ~1-2s trong khi SDK fetch ad.
class BannerScreen extends StatelessWidget {
  const BannerScreen({super.key, required this.preloaded});

  /// Preloaded controller owned by [HomeScreen]; this screen does not
  /// dispose it.
  /// Controller preload do [HomeScreen] sở hữu; screen này không
  /// dispose nó.
  final BannerAdController? preloaded;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blueGrey,
      appBar: AppBar(
        title: const Text('Banner Demo'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(),
            const _Label(
                '1. Preload — instant render (no loading state)\n'
                'Preload — render tức thì (không hiện loading)'),
            MyBannerAd.control(
              controller: preloaded,
              loadingWidget: const AdLoading(height: 60),
            ),
            const SizedBox(height: 30),
            const _Label(
                '2. Inline — load on mount (loading state visible)\n'
                'Inline — load lúc mount (thấy loading)'),
            const MyBannerAd(
              adId: _adId,
              isCollapsible: true,
              adKey: _inlineAdKey,
              loadingWidget: AdLoading(height: 60),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
