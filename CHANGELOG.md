## 1.1.0

### Breaking changes

- Bump `google_mobile_ads` to `^8.0.0` (was `^7.0.0`). Hosts must
  use Android `compileSdk 36` + JDK 17 and iOS deployment target
  `15.0+`.
- Bump `internet_connection_checker_plus` to `^3.0.0` (was `^2.9.1+2`).
- Bump min Dart SDK to `3.10.0` and min Flutter SDK to `3.38.1`.
- Banner anchored adaptive size now uses
  `getLargeAnchoredAdaptiveBannerAdSize` (the only non-deprecated
  variant in GMA 8.x). Banners render taller than 1.0.0.

### Other

- Plugin Android `compileSdk` 34 → 36, JDK 1.8 → 17,
  `play-services-ads` 24.6.0 → 25.1.0.
- Shortened `pubspec.yaml` description to satisfy pub.dev 180-char
  limit.

## 1.0.0

First public release of **flutter_ads_plus** — a wrapper for
`google_mobile_ads` with native PreloadV2 buffering, per-controller
event streams, a built-in app-open-resume reactor, and ready-to-use
widgets for all 5 AdMob ad formats.

### Features

- 5 ad formats with matching widget + controller:
  - Banner (`BannerAdController`, `MyBannerAd` / `MyBannerAd.control`)
  - Native (`NativeAdController`, `MyNativeAd` / `MyNativeAd.control`,
    plus `MyNativeAd2` for impression-triggered swap-in)
  - Interstitial (`InterstitialAdController`, `MyInterstitialAd`,
    `MyAds.showInterstitialAd`)
  - Rewarded (`RewardedAdController`, `MyRewardedAd`,
    `MyAds.showRewardAd`)
  - App Open (`AppOpenAdController`, `MyAppOpenAd`,
    `MyAds.showAppOpenAd`)
- **Native PreloadV2** integration for interstitial + app-open:
  - `MyAds.preloadInterstitialAd(adId:, bufferSize:)`
  - `MyAds.preloadAppOpenAd(adId:, bufferSize:)`
  - `MyAds.showInterstitialAd` / `showAppOpenAd` / `showSplashAd`
    automatically prefer the native buffer when available.
- **App-open-resume** via `AppLifecycleReactor`:
  - `MyAds.initAppOpenAd(...)` enables auto-show on foreground.
  - `setIsExcludeScreen` for one-shot exclusions.
  - `setSingleUseAdId` for one-shot ad-id overrides.
  - Optional native-format overlay via `nativeFullAdId` +
    `enableNativeFullResume`.
- **Two consumption patterns** per format:
  - Preload via controller (instant show when reached).
  - Inline (load + show on demand with overlay loading state).
- Full-screen **loading overlay** with 3 styles:
  - `LottieLoadingConfig` (12 bundled animations, random pick).
  - `VideoLoadingConfig` (asset / network / file).
  - `WidgetLoadingConfig` (any custom widget).
- Throttling: `MyAds.interIntervalInSeconds` between interstitials,
  bypassed with `forceShow: true`.
- Per-`adKey` **show-rate logger** in `MyAds.showRate`.
- Single broadcast `MyAds.events` stream emitting `AdInformation`
  records for every status transition (load / impression / paid /
  dismiss / ...).
- Bilingual DartDoc (English + Tiếng Việt) on the public surface.

### Requirements

- Flutter 3.0+
- Android `minSdkVersion` 23, `compileSdk` 34
- iOS 13.0+
- AdMob App ID configured in `AndroidManifest.xml` +
  `ios/Runner/Info.plist`
