# flutter_ads_plus

[English](README.md) · [🇻🇳 Tiếng Việt](README.vi.md)

Wrapper for `google_mobile_ads` with native PreloadV2 buffering, per-controller event streams, a built-in app-open-resume reactor, and ready-to-use widgets for all 5 AdMob ad formats.

---

## Demo

<p align="center">
  <img src="screenshots/demo_ads.gif" alt="flutter_ads_plus demo" width="320">
</p>

---

## Features

- 5 ad formats: **Banner**, **Native**, **Interstitial**, **Rewarded**, **AppOpen**.
- **Native PreloadV2** buffer for interstitial + app-open (instant show, no Dart load round-trip).
- **App-open-resume** auto-show when the app returns to foreground, with cooldown rules.
- Two consumption patterns per format: **preload-via-controller** (instant show) and **inline** (load on demand).
- Full-screen **loading overlay** (Lottie / video / custom widget).
- Per-`adKey` **show-rate** logger.
- Single broadcast `events` stream covering every ad event app-wide.

---

## Setup

### 1. Add dependency

```yaml
dependencies:
  flutter_ads_plus: ^1.1.0
```

Or via CLI:

```sh
flutter pub add flutter_ads_plus
```

### 2. Android

#### `android/app/src/main/AndroidManifest.xml`

```xml
<application ...>
  <meta-data
    android:name="com.google.android.gms.ads.APPLICATION_ID"
    android:value="ca-app-pub-XXXXXXXXXXXXXXXX~YYYYYYYYYY"/>
</application>
```

#### `android/app/build.gradle`

```gradle
android {
  defaultConfig {
    minSdk = 23
    multiDexEnabled true
  }
}
```

#### `MainActivity.kt` — register native ad factories

For every Native ad layout you want to use, implement a `NativeAdFactory` on the platform side and register it with a string id:

```kotlin
override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
  super.configureFlutterEngine(flutterEngine)
  GoogleMobileAdsPlugin.registerNativeAdFactory(
    flutterEngine,
    "mySmallNativeAd",
    MySmallNativeAdFactory(context),
  )
}

override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
  super.cleanUpFlutterEngine(flutterEngine)
  GoogleMobileAdsPlugin.unregisterNativeAdFactory(flutterEngine, "mySmallNativeAd")
}
```

See `example/android/app/src/main/kotlin/.../*.kt` for 5 working factories you can copy: `SmallNativeAd`, `HomeNativeAd`, `NormalNativeAd` (top/bottom button), `ExtraNativeAd`, `FullNativeAd`.

### 3. iOS

#### `ios/Runner/Info.plist`

```xml
<key>GADApplicationIdentifier</key>
<string>ca-app-pub-XXXXXXXXXXXXXXXX~YYYYYYYYYY</string>
```

#### `AppDelegate.swift` — register native ad factories

```swift
let factory = MySmallNativeAdFactory()
FLTGoogleMobileAdsPlugin.registerNativeAdFactory(
  self,
  factoryId: "mySmallNativeAd",
  nativeAdFactory: factory
)
```

---

## Initialize

Call **once** at app start. The recommended place is the splash screen's `initState` — initialize there, then navigate to home when ready.

```dart
final navigatorKey = GlobalKey<NavigatorState>();

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(MaterialApp(
    navigatorKey: navigatorKey,
    home: const SplashScreen(),
  ));
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    await MyAds.instance.initialize(
      navigatorKey: navigatorKey,
      enableEventLogger: true,
      enableShowRateLogger: true,
      interIntervalInSeconds: 20,           // throttle between interstitials
      timeShowAdInterAfterAdOpen: 5,        // cooldown after app-open
      fullScreenLoadingConfig: LottieLoadingConfig(
        lottiePaths: ['assets/loading.json'],
      ),
    );

    // Optional — kick off any controller-based or native preload here so
    // ads are warm by the time the user reaches the home screen.
    await MyAds.instance.preloadInterstitialAd(adId: '...', bufferSize: 1);

    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const HomeScreen()),
    );
  }

  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Center(child: CircularProgressIndicator()));
}
```

> 💡 If you want to show an interstitial / app-open ad **on the splash screen itself** before navigating home, use [`MyAds.showSplashAd`](#splash-flow) instead of navigating in `_bootstrap`. The Splash flow section covers this.

---

## Two consumption patterns

Every ad format supports two patterns. Pick based on UX priority.

| Pattern | When | UX | Code |
|---|---|---|---|
| **Preload (controller)** | High-priority placement, no loading delay allowed (entry screen, after a critical action) | Ad renders **instantly** — no loading state visible | Create controller + `load()` **before** the user reaches the show point. Pass it to the widget / show function. |
| **Inline (no controller)** | Low-frequency or non-critical placement | User sees a **loading state** for ~1-2s while the SDK loads | Pass `adId` directly. The library builds the controller internally on mount. |

---

## Banner

### Preload

Create + `load()` the controller in a screen that's mounted **before** the banner is shown (e.g. home screen). Pass it via `MyBannerAd.control`.

```dart
class _HomeScreenState extends State<HomeScreen> {
  late final BannerAdController _banner;

  @override
  void initState() {
    super.initState();
    _banner = BannerAdController(
      adId: 'ca-app-pub-...',
      isCollapsible: true,
      adKey: 'banner_home',
    )..load();
  }

  @override
  void dispose() {
    _banner.dispose();
    super.dispose();
  }

  void _openBannerDemo() => Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => BannerScreen(preloaded: _banner)),
  );
}

// In BannerScreen:
MyBannerAd.control(
  controller: widget.preloaded,
  loadingWidget: const AdLoading(height: 60),
)
```

### Inline

```dart
const MyBannerAd(
  adId: 'ca-app-pub-...',
  isCollapsible: true,
  adKey: 'banner_inline',
)
```

---

## Native

> Requires the matching `NativeAdFactory` registered on Android + iOS (see Setup).

### Preload

```dart
final controller = NativeAdController(
  adId: 'ca-app-pub-...',
  factoryId: 'mySmallNativeAd',
  adKey: 'native_home',
)..load();

// Later:
MyNativeAd.control(
  controller: controller,
  height: 280,
  loadingWidget: const LargeAdLoading(),
)
```

### Inline

```dart
MyNativeAd(
  adId: 'ca-app-pub-...',
  factoryId: 'mySmallNativeAd',
  adKey: 'native_inline',
  height: 280,
)
```

---

## Interstitial

### Preload (instant show)

```dart
// At app start / home screen:
final interController = InterstitialAdController(
  adId: 'ca-app-pub-...',
  adKey: 'inter_action',
)..load();

// When user taps the action:
await MyAds.instance.showInterstitialAd(
  context,
  adId: 'ca-app-pub-...',
  controller: interController,
  adKey: 'inter_action',
  forceShow: true,
  onShowed: () => print('shown'),
  adDismissed: () => print('dismissed'),
);
```

> ⚠️ The fullscreen runner disposes the controller after dismiss. To keep subsequent shows instant, recreate the controller — see the **preload-chain recipe** below.

### Inline (load + show on demand)

```dart
await MyAds.instance.showInterstitialAd(
  context,
  adId: 'ca-app-pub-...',
  adKey: 'inter_inline',
);
```

The runner builds a controller, calls `load()`, and shows the full-screen loading overlay until the ad is ready.

---

## Rewarded

Same shape as Interstitial. Add `onUserEarnedReward` for the reward grant.

```dart
// Preload:
final rewardController = RewardedAdController(
  adId: 'ca-app-pub-...',
  adKey: 'reward_video',
)..load();

MyAds.instance.showRewardAd(
  context,
  adId: 'ca-app-pub-...',
  controller: rewardController,
  adKey: 'reward_video',
  onUserEarnedReward: () => grantReward(),
);
```

---

## App Open

### Manual show

```dart
final appOpenController = AppOpenAdController(
  adId: 'ca-app-pub-...',
  adKey: 'app_open',
)..load();

await MyAds.instance.showAppOpenAd(
  context,
  adId: 'ca-app-pub-...',
  controller: appOpenController,
  adKey: 'app_open',
);
```

### Auto-resume (recommended)

Configure once at app start. The library listens to app foreground transitions and shows the ad automatically.

```dart
MyAds.instance.initAppOpenAd(
  appOpenAdUnitId: 'ca-app-pub-...',
  autoEnable: true,            // start auto-showing now
  bufferSize: 1,               // also kicks off native preload
  nativeFullAdId: '...',       // optional: overlay native ad on top
);
```

#### Exclude one transition

```dart
// Before opening a custom flow (e.g. OAuth WebView):
MyAds.instance.appLifecycleReactor?.setIsExcludeScreen(true);
```

Auto-clears after one transition.

#### One-shot override

```dart
MyAds.instance.appLifecycleReactor?.setSingleUseAdId(id: 'promo-ad-id');
// next resume → shows promo-ad-id; subsequent resumes → main id
```

---

## Native PreloadV2 (instant interstitial / app-open)

The platform side keeps a buffer of pre-fetched ads. `showInterstitialAd / showAppOpenAd / showSplashAd` automatically use this buffer when available.

```dart
await MyAds.instance.preloadInterstitialAd(
  adId: 'ca-app-pub-...',
  bufferSize: 1,                  // how many ads to keep warm
  onAdPreloaded: () => print('preloaded'),
  onAdFailedToPreload: (code, msg, domain) => print('fail $msg'),
);

await MyAds.instance.preloadAppOpenAd(
  adId: 'ca-app-pub-...',
  bufferSize: 1,
);
```

Difference vs controller-preload:

| | Controller preload | Native preload (PreloadV2) |
|---|---|---|
| Buffer lives in | Dart object (per-controller) | Platform native pipeline (shared) |
| Survives controller dispose | No | Yes |
| Best for | Specific placement, single use | App-wide pool, splash, ads-heavy flows |
| Use with | `MyAds.showXxxAd(controller: ...)` | `MyAds.showXxxAd(adId: ...)` — auto-detected |

---

## Splash flow

```dart
await MyAds.instance.showSplashAd(
  context,
  adId: 'ca-app-pub-...',
  useInterAd: true,            // true = interstitial, false = app-open
  showLoading: true,
  onShowed: () => goToHome(),
  onFailed: () => goToHome(),
  onNoInternet: () => goToHome(),
  adDismissed: () => goToHome(),
);
```

`showSplashAd` uses the preload-first algorithm: tries the native PreloadV2 buffer first, falls back to a fresh `load()` if empty.

---

## Recipe: preload-chain (always-instant fullscreen)

After a fullscreen ad dismisses, the runner disposes its controller. To keep every show "instant", rebuild the controller right after the dismiss event:

```dart
class _AppRootState extends State<AppRoot> {
  InterstitialAdController? _interController;
  StreamSubscription<AdInformation>? _sub;

  static const _adId = 'ca-app-pub-...';
  static const _adKey = 'inter_main';

  @override
  void initState() {
    super.initState();
    _rebuild();
    _sub = MyAds.instance.events.listen((event) {
      if (event.status.isDismiss && event.adKey == _adKey) {
        _rebuild();
      }
    });
  }

  void _rebuild() {
    _interController = InterstitialAdController(
      adId: _adId,
      adKey: _adKey,
    )..load();
  }

  @override
  void dispose() {
    _sub?.cancel();
    _interController?.dispose();
    super.dispose();
  }
}
```

When the user taps an action, pass `_interController` to `MyAds.showInterstitialAd(controller: _interController, ...)` — instant show.

See `example/lib/home_screen.dart` for a full working example covering all 4 fullscreen types.

---

## Events stream

Single broadcast stream of every ad event across the entire app. Useful for analytics, attribution, and revenue reporting.

```dart
MyAds.instance.events.listen((event) {
  // event.status, event.type, event.adId, event.adKey,
  // event.valueMicros, event.currencyCode (when status.isPaid)
  if (event.status.isPaid) {
    analytics.logAdRevenue(
      revenue: event.valueMicros! / 1000000,
      currency: event.currencyCode!,
      adFormat: event.type.name,
      adKey: event.adKey,
    );
  }
});
```

---

## Show-rate logger

Per-`adKey` request / impression counts. Enable once at init, label every ad with a unique `adKey`.

```dart
await MyAds.instance.initialize(
  navigatorKey: navigatorKey,
  enableShowRateLogger: true,
);

// Access at any time:
print(MyAds.instance.showRate); // Map<adKey, ShowRateInfo>
```

---

## Custom loading overlay

Pick the style at init. Defaults to 12 bundled Lottie animations.

```dart
// Option 1: Lottie (default + custom list)
fullScreenLoadingConfig: LottieLoadingConfig(
  lottiePaths: ['assets/lottie/spinner.json'],
  loadingText: 'Loading ad...',
  size: 200,
),

// Option 2: Video
fullScreenLoadingConfig: VideoLoadingConfig(
  path: 'assets/loading.mp4',
  type: VideoType.asset,
),

// Option 3: Custom widget
fullScreenLoadingConfig: WidgetLoadingConfig(
  loadingWidget: const Center(child: CircularProgressIndicator()),
),
```

---

## Rate-limiting interstitials

By default, `showInterstitialAd` is throttled by `interIntervalInSeconds` (20s). Bypass with `forceShow: true`.

```dart
// Configured throttle:
await MyAds.instance.initialize(
  navigatorKey: navigatorKey,
  interIntervalInSeconds: 30,
);

// Force ignore throttle (e.g. splash flow):
MyAds.instance.showInterstitialAd(
  context,
  adId: '...',
  forceShow: true,
);
```

---

## Status reference

`AdStatus` values emitted on `events` and on each controller's `stream`:

| Status | When |
|---|---|
| `init` | Created or disposed |
| `loading` | `XxxAd.load(...)` in flight |
| `loaded` | SDK reported success |
| `loadFailed` | SDK reported failure |
| `shown` | Fullscreen ad on screen |
| `impression` | First valid impression |
| `clicked` | User clicked |
| `paid` | Paid event (revenue) |
| `dismiss` | User closed the ad |
| `showFailed` | Show step failed |
| `earnReward` | Reward earned (rewarded only) |
| `opened`, `closed` | Banner/native lifecycle |

Composite: `status.isShowOnScreen` = the ad is actually visible right now (post-load, pre-dismiss).

---

## License

MIT
