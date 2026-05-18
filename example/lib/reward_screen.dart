import 'package:flutter/material.dart';
import 'package:flutter_ads_plus/flutter_ads_plus.dart';

import 'home_screen.dart';

const _inlineAdKey = 'reward_inline';

/// Two-variant rewarded ad demo.
///
/// 1. **Preload** — uses the controller pre-loaded by [HomeScreen]; the
///    first tap shows instantly. HomeScreen recreates the controller on
///    dismiss for repeat runs.
/// 2. **Inline** — `MyAds.showRewardAd` with only `adId`; the runner
///    builds + loads + shows.
///
/// Demo reward 2 biến thể.
///
/// 1. **Preload** — dùng controller [HomeScreen] đã preload; lần tap
///    đầu show tức thì. HomeScreen recreate controller khi dismiss để
///    lần sau cũng sẵn.
/// 2. **Inline** — `MyAds.showRewardAd` chỉ với `adId`; runner tự
///    build + load + show.
class RewardScreen extends StatelessWidget {
  const RewardScreen({
    super.key,
    required this.adId,
    required this.preloaded,
  });

  final String adId;
  final RewardedAdController? preloaded;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blueGrey,
      appBar: AppBar(
        title: const Text('Reward Demo'),
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
                onPressed: () {
                  MyAds.instance.showRewardAd(
                    context,
                    adId: adId,
                    controller: preloaded,
                    adKey: kRewardKey,
                    onShowed: () => debugPrint('Preloaded reward shown'),
                    onFailed: () => debugPrint('Preloaded reward failed'),
                    onUserEarnedReward: () =>
                        debugPrint('Preloaded reward earned'),
                    adDismissed: () =>
                        debugPrint('Preloaded reward dismissed'),
                  );
                },
                child: const Text('1. Preload + show (controller)'),
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () {
                  MyAds.instance.showRewardAd(
                    context,
                    adId: adId,
                    adKey: _inlineAdKey,
                    onShowed: () => debugPrint('Inline reward shown'),
                    onFailed: () => debugPrint('Inline reward failed'),
                    onUserEarnedReward: () =>
                        debugPrint('Inline reward earned'),
                    adDismissed: () => debugPrint('Inline reward dismissed'),
                  );
                },
                child: const Text('2. Load + show inline (no controller)'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
