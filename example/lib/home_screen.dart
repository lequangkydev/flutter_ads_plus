import 'dart:async';
import 'dart:io';

import 'package:ads/ad_factory.dart';
import 'package:ads/banner_screen.dart';
import 'package:ads/inter_screen.dart';
import 'package:ads/native_screen.dart';
import 'package:ads/open_resume_screen.dart';
import 'package:ads/reward_screen.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_ads_plus/flutter_ads_plus.dart';

import 'main.dart';

// Test ad unit ids — replace with your own in production.
// ID ad test — đổi sang ID thật khi vào production.
const _bannerId = 'ca-app-pub-3940256099942544/8388050270';
const _nativeId = 'ca-app-pub-3940256099942544/2247696110';
const _rewardId = 'ca-app-pub-3940256099942544/5224354917';
String get _interId => Platform.isAndroid
    ? 'ca-app-pub-3940256099942544/1033173712'
    : 'ca-app-pub-3940256099942544/4411468910';
String get _appOpenId => Platform.isAndroid
    ? 'ca-app-pub-3940256099942544/9257395921'
    : 'ca-app-pub-3940256099942544/5575463023';

// Keys used by the preload pattern. The dismiss listener uses them to
// know which controller to recreate.
// Key cho pattern preload. Listener dismiss dựa vào key để biết nên
// recreate controller nào.
const kBannerKey = 'banner_preload';
const kInterKey = 'inter_preload';
const kRewardKey = 'reward_preload';
const kAppOpenKey = 'app_open_preload';

/// Native-ad layout variants demoed on [NativeScreen]. Each gets its own
/// preloaded controller below.
/// Các biến thể layout native demo ở [NativeScreen]. Mỗi cái có
/// controller preload riêng bên dưới.
const kNativeDemoFactories = [
  AdFactory.topNormalNativeAd,
  AdFactory.bottomNormalNativeAd,
  AdFactory.homeNativeAd,
  AdFactory.smallNativeAd,
];

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Long-lived display controllers shared across navigations. Loading
  // happens *before* the user enters a demo screen, so the screen
  // renders the ad instantly.
  // Controller display long-lived dùng chung giữa các lần navigation.
  // Load xảy ra *trước* khi user vào screen demo nên ad render tức thì.
  BannerAdController? _bannerController;
  final Map<AdFactory, NativeAdController> _nativeControllers = {};

  // Single-use fullscreen controllers. Recreated by [_onAdEvent] after
  // each dismiss so the next entry to the screen is also "preloaded".
  // Controller fullscreen single-use. [_onAdEvent] recreate sau mỗi
  // dismiss để lần vào screen kế tiếp cũng "preloaded".
  InterstitialAdController? _interController;
  RewardedAdController? _rewardController;
  AppOpenAdController? _appOpenController;

  StreamSubscription<AdInformation>? _eventsSub;

  @override
  void initState() {
    initAds();
    super.initState();
  }

  Future<void> initAds() async {
    await MyAds.instance.initialize(
      navigatorKey: navigatorKey,
      enableEventLogger: false,
      enableShowRateLogger: true,
      fullScreenLoadingConfig: LottieLoadingConfig(
        lottiePaths: [
          'assets/loading.json',
          'assets/loading2.json',
          'assets/loading3.json',
        ],
      ),
      reloadNativeAdWhenClicked: true,
    );

    MyAds.instance.initAppOpenAd(
      appOpenAdUnitId: _appOpenId,
      bufferSize: 0,
    );

    await MyAds.instance.preloadInterstitialAd(
      adId: _interId,
      bufferSize: 1,
    );

    _preloadAll();
    _eventsSub = MyAds.instance.events.listen(_onAdEvent);
  }

  void _preloadAll() {
    _bannerController = BannerAdController(
      adId: _bannerId,
      isCollapsible: true,
      adKey: kBannerKey,
    )..load();

    // One NativeAdController per layout variant demoed on NativeScreen.
    // Mỗi biến thể layout demo có 1 NativeAdController riêng.
    for (final factory in kNativeDemoFactories) {
      _nativeControllers[factory] = NativeAdController(
        adId: _nativeId,
        factoryId: factory.name,
        adKey: 'native_${factory.name}',
      )..load();
    }

    _interController = InterstitialAdController(
      adId: _interId,
      adKey: kInterKey,
    )..load();
    _rewardController = RewardedAdController(
      adId: _rewardId,
      adKey: kRewardKey,
    )..load();
    _appOpenController = AppOpenAdController(
      adId: _appOpenId,
      adKey: kAppOpenKey,
    )..load();
  }

  void _onAdEvent(AdInformation event) {
    if (!event.status.isDismiss) return;
    switch (event.type) {
      case AdType.interstitial:
        if (event.adKey == kInterKey) {
          _interController = InterstitialAdController(
            adId: _interId,
            adKey: kInterKey,
          )..load();
        }
        break;
      case AdType.reward:
        if (event.adKey == kRewardKey) {
          _rewardController = RewardedAdController(
            adId: _rewardId,
            adKey: kRewardKey,
          )..load();
        }
        break;
      case AdType.appOpen:
        if (event.adKey == kAppOpenKey) {
          _appOpenController = AppOpenAdController(
            adId: _appOpenId,
            adKey: kAppOpenKey,
          )..load();
        }
        break;
      default:
    }
  }

  @override
  void dispose() {
    _eventsSub?.cancel();
    _bannerController?.dispose();
    for (final c in _nativeControllers.values) {
      c.dispose();
    }
    _interController?.dispose();
    _rewardController?.dispose();
    _appOpenController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Flutter Ads Plus Demo'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              _button('Banner', () {
                Navigator.of(context).push(CupertinoPageRoute(
                  builder: (context) =>
                      BannerScreen(preloaded: _bannerController),
                ));
              }),
              _button('Native (4 layouts)', () {
                Navigator.of(context).push(CupertinoPageRoute(
                  builder: (context) =>
                      NativeScreen(preloaded: _nativeControllers),
                ));
              }),
              _button('Inter', () {
                Navigator.of(context).push(CupertinoPageRoute(
                  builder: (context) => InterScreen(
                    adId: _interId,
                    preloaded: _interController,
                  ),
                ));
              }),
              _button('Open Resume', () {
                Navigator.of(context).push(CupertinoPageRoute(
                  builder: (context) => ResumeScreen(
                    adId: _appOpenId,
                    preloaded: _appOpenController,
                  ),
                ));
              }),
              _button('Reward', () {
                Navigator.of(context).push(CupertinoPageRoute(
                  builder: (context) => RewardScreen(
                    adId: _rewardId,
                    preloaded: _rewardController,
                  ),
                ));
              })
            ],
          ),
        ),
      ),
    );
  }

  Widget _button(String title, VoidCallback action) {
    return InkWell(
      onTap: action,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 10),
        height: 50,
        decoration: BoxDecoration(
            color: Colors.blueAccent, borderRadius: BorderRadius.circular(10)),
        child: Center(
          child: Text(
            title,
            style: const TextStyle(color: Colors.white, fontSize: 20),
          ),
        ),
      ),
    );
  }
}
