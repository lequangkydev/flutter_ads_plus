import 'package:flutter/material.dart';
import 'package:flutter_ads_plus/flutter_ads_plus.dart';

import 'ad_factory.dart';

/// Heights tuned per layout to avoid clipping or excessive empty space.
/// Chiều cao tinh chỉnh theo từng layout để khỏi bị cắt / dư khoảng trắng.
const Map<AdFactory, double> _heights = {
  AdFactory.topNormalNativeAd: 320,
  AdFactory.bottomNormalNativeAd: 320,
  AdFactory.homeNativeAd: 160,
  AdFactory.smallNativeAd: 80,
};

const Map<AdFactory, String> _labels = {
  AdFactory.topNormalNativeAd:
      '1. Top button / Nút ở trên (topNormalNativeAd)',
  AdFactory.bottomNormalNativeAd:
      '2. Bottom button / Nút ở dưới (bottomNormalNativeAd)',
  AdFactory.homeNativeAd: '3. Home (homeNativeAd)',
  AdFactory.smallNativeAd: '4. Small (smallNativeAd)',
};

/// Demo của 4 layout native ad — cùng adId, chỉ khác `factoryId`.
/// Mỗi layout đã preload sẵn ở [HomeScreen] và truyền vào qua
/// [preloaded] → ad render tức thì khi screen mount.
///
/// Demo of 4 native ad layouts — same adId, only `factoryId` differs.
/// Each layout is pre-loaded by [HomeScreen] and passed in via
/// [preloaded] so the ad renders instantly when the screen mounts.
class NativeScreen extends StatelessWidget {
  const NativeScreen({super.key, required this.preloaded});

  /// Map factory → preloaded controller, owned by [HomeScreen].
  /// Map factory → controller preload, do [HomeScreen] sở hữu.
  final Map<AdFactory, NativeAdController> preloaded;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blueGrey,
      appBar: AppBar(
        title: const Text('Native Demo'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 16),
          children: [
            for (final factory in _labels.keys) _section(factory),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _section(AdFactory factory) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Label(_labels[factory]!),
        MyNativeAd.control(
          controller: preloaded[factory],
          height: _heights[factory]!,
          loadingWidget: const LargeAdLoading(),
        ),
        const SizedBox(height: 24),
      ],
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
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
