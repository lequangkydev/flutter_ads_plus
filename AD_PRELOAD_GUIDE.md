# Hướng dẫn sử dụng Quảng cáo Preload (App Open & Interstitial)

---

## 0. Cấu hình
File `pubspec.yaml`:
```yaml
dependencies:
  flutter_ads_plus: ^1.0.0
```

> Bật preload khi initialize để có luôn phần preload open resume và splash(inter or appOpen).
```dart
await MyAds.instance.initialize(
  allowPreload: true,
);
```
> Dưa **`allowPreload`** vào **Remote Config**.

### Gọi showSplashAd để dùng preload splash
```dart
await MyAds.instance.showSplashAd(
  context,
  adId: splashConfig.id,
  useInterAd: true, // true dùng Inter, false dùng AppOpen
);
```
---

## 1. Tạo PreloadAdUtil

```dart
class PreloadAdUtil {
  PreloadAdUtil._();

  static PreloadAdUtil instance = PreloadAdUtil._();

  Future<void> preloadInterAd({
    required AdUnitConfig adConfig,
    int bufferSize = 1,
  }) async {
    if (!adConfig.isEnable) {
      return;
    }
    await MyAds.instance.preloadInterstitialAd(
      adId: adConfig.id,
      bufferSize: bufferSize,
    );
  }

  Future<void> preloadAppOpenAd({
    required AdUnitConfig adConfig,
    int bufferSize = 1,
  }) async {
    if (!adConfig.isEnable) {
      return;
    }
    await MyAds.instance.preloadAppOpenAd(
      adId: adConfig.id,
      bufferSize: bufferSize,
    );
  }
}
```

## 2. Load (Preload)

Gọi `PreloadAdUtil` trước khi hiển thị để có preload.

### Load App Open Ad
```dart
await PreloadAdUtil.instance.preloadAppOpenAd(
  adConfig: appOpenConfigs,
);
```

### Load Interstitial Ad
```dart
await PreloadAdUtil.instance.preloadInterAd(
  adConfig: interstitialConfigs,
);
```