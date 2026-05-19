# flutter_ads_plus

[🇬🇧 English](README.md) · [Tiếng Việt](README.vi.md)

Wrapper cho `google_mobile_ads` kèm native PreloadV2 buffering, stream event theo từng controller, reactor app-open-resume sẵn, và widget dùng ngay cho cả 5 ad format của AdMob.

---

## Demo

<p align="center">
  <img src="screenshots/demo_ads.gif" alt="flutter_ads_plus demo" width="320">
</p>

---

## Tính năng

- 5 ad format: **Banner**, **Native**, **Interstitial**, **Rewarded**, **AppOpen**.
- Buffer **Native PreloadV2** cho interstitial + app-open (show tức thì, không cần load từ Dart).
- **App-open-resume** tự show khi app trở lại foreground, có quy tắc cooldown.
- 2 pattern sử dụng cho mỗi format: **preload qua controller** (show tức thì) và **inline** (load on demand).
- **Loading overlay** full-screen (Lottie / video / widget tuỳ chỉnh).
- Logger **show-rate** theo `adKey`.
- 1 broadcast stream `events` duy nhất phủ toàn bộ ad event của app.

---

## Cài đặt

### 1. Thêm dependency

```yaml
dependencies:
  flutter_ads_plus: ^1.1.0
```

Hoặc qua CLI:

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

#### `MainActivity.kt` — đăng ký Native ad factory

Với mỗi layout Native muốn dùng, implement 1 `NativeAdFactory` ở platform side và đăng ký với id dạng string:

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

Xem `example/android/app/src/main/kotlin/.../*.kt` có sẵn 5 factory để copy: `SmallNativeAd`, `HomeNativeAd`, `NormalNativeAd` (button trên/dưới), `ExtraNativeAd`, `FullNativeAd`.

### 3. iOS

#### `ios/Runner/Info.plist`

```xml
<key>GADApplicationIdentifier</key>
<string>ca-app-pub-XXXXXXXXXXXXXXXX~YYYYYYYYYY</string>
```

#### `AppDelegate.swift` — đăng ký Native ad factory

```swift
let factory = MySmallNativeAdFactory()
FLTGoogleMobileAdsPlugin.registerNativeAdFactory(
  self,
  factoryId: "mySmallNativeAd",
  nativeAdFactory: factory
)
```

---

## Khởi tạo

Gọi **một lần** lúc app khởi động. Vị trí khuyến nghị là `initState` của splash screen — init xong rồi navigate sang home.

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
      interIntervalInSeconds: 20,           // throttle giữa các inter
      timeShowAdInterAfterAdOpen: 5,        // cooldown sau app-open
      fullScreenLoadingConfig: LottieLoadingConfig(
        lottiePaths: ['assets/loading.json'],
      ),
    );

    // Tuỳ chọn — kick off controller / native preload tại đây để ad đã
    // warm khi user vào home.
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

> 💡 Nếu muốn show inter / app-open ad **ngay trên splash** trước khi vào home, dùng [`MyAds.showSplashAd`](#splash-flow) thay cho việc navigate trực tiếp trong `_bootstrap`. Xem section Splash flow.

---

## 2 pattern sử dụng

Mọi ad format đều hỗ trợ 2 pattern. Chọn theo UX priority.

| Pattern | Khi nào | UX | Code |
|---|---|---|---|
| **Preload (controller)** | Vị trí ưu tiên cao, không cho phép loading delay (màn đầu, sau action quan trọng) | Ad render **tức thì** — không thấy loading state | Tạo controller + `load()` **trước** khi user đến điểm show. Truyền vào widget / show function. |
| **Inline (không controller)** | Vị trí tần suất thấp / không critical | User thấy **loading state** ~1-2s trong khi SDK load | Truyền `adId` trực tiếp. Library tự build controller bên trong lúc mount. |

---

## Banner

### Preload

Tạo + `load()` controller ở screen mount **trước** khi banner hiển thị (vd. home screen). Truyền qua `MyBannerAd.control`.

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

// Trong BannerScreen:
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

> Yêu cầu `NativeAdFactory` tương ứng đã đăng ký ở Android + iOS (xem Cài đặt).

### Preload

```dart
final controller = NativeAdController(
  adId: 'ca-app-pub-...',
  factoryId: 'mySmallNativeAd',
  adKey: 'native_home',
)..load();

// Sau đó:
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

### Preload (show tức thì)

```dart
// Lúc app khởi động / home screen:
final interController = InterstitialAdController(
  adId: 'ca-app-pub-...',
  adKey: 'inter_action',
)..load();

// Khi user tap action:
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

> ⚠️ Runner fullscreen sẽ dispose controller sau khi dismiss. Để các lần show sau cũng instant → recreate controller — xem **công thức preload-chain** bên dưới.

### Inline (load + show on demand)

```dart
await MyAds.instance.showInterstitialAd(
  context,
  adId: 'ca-app-pub-...',
  adKey: 'inter_inline',
);
```

Runner tự build controller, gọi `load()`, hiển thị overlay loading toàn màn đến khi ad sẵn sàng.

---

## Rewarded

Cùng pattern với Interstitial. Thêm `onUserEarnedReward` để cấp reward.

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

### Show thủ công

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

### Auto-resume (khuyến nghị)

Cấu hình 1 lần lúc app khởi động. Library tự lắng nghe foreground transition và show ad tự động.

```dart
MyAds.instance.initAppOpenAd(
  appOpenAdUnitId: 'ca-app-pub-...',
  autoEnable: true,            // bật auto-show ngay
  bufferSize: 1,               // đồng thời kick off native preload
  nativeFullAdId: '...',       // tuỳ chọn: phủ native ad lên trên
);
```

#### Bỏ qua 1 lần resume

```dart
// Trước khi mở flow tuỳ chỉnh (vd. OAuth WebView):
MyAds.instance.appLifecycleReactor?.setIsExcludeScreen(true);
```

Tự reset sau 1 transition.

#### Override 1 lần

```dart
MyAds.instance.appLifecycleReactor?.setSingleUseAdId(id: 'promo-ad-id');
// resume tiếp theo → show promo-ad-id; các resume sau → main id
```

---

## Native PreloadV2 (instant interstitial / app-open)

Platform side giữ buffer ad đã fetch sẵn. `showInterstitialAd / showAppOpenAd / showSplashAd` tự dùng buffer này khi có.

```dart
await MyAds.instance.preloadInterstitialAd(
  adId: 'ca-app-pub-...',
  bufferSize: 1,                  // số ad giữ warm
  onAdPreloaded: () => print('preloaded'),
  onAdFailedToPreload: (code, msg, domain) => print('fail $msg'),
);

await MyAds.instance.preloadAppOpenAd(
  adId: 'ca-app-pub-...',
  bufferSize: 1,
);
```

So với controller-preload:

| | Controller preload | Native preload (PreloadV2) |
|---|---|---|
| Buffer ở đâu | Dart object (mỗi controller 1 buffer) | Pipeline native (dùng chung) |
| Sống sau khi controller dispose? | Không | Có |
| Phù hợp với | Vị trí cụ thể, dùng 1 lần | Pool toàn app, splash, flow nhiều ad |
| Dùng với | `MyAds.showXxxAd(controller: ...)` | `MyAds.showXxxAd(adId: ...)` — auto-detect |

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

`showSplashAd` dùng thuật toán preload-first: thử buffer native PreloadV2 trước, fallback load mới nếu rỗng.

---

## Công thức: preload-chain (fullscreen luôn instant)

Sau khi fullscreen dismiss, runner dispose controller. Để mọi lần show đều "instant", rebuild controller ngay sau event dismiss:

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

Khi user tap action, pass `_interController` vào `MyAds.showInterstitialAd(controller: _interController, ...)` → show tức thì.

Xem `example/lib/home_screen.dart` để có ví dụ hoàn chỉnh phủ cả 4 loại fullscreen.

---

## Events stream

1 broadcast stream của mọi ad event trên toàn app. Hữu ích cho analytics, attribution, báo cáo doanh thu.

```dart
MyAds.instance.events.listen((event) {
  // event.status, event.type, event.adId, event.adKey,
  // event.valueMicros, event.currencyCode (khi status.isPaid)
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

Đếm request / impression theo `adKey`. Bật 1 lần lúc init, gán `adKey` duy nhất cho mỗi vị trí ad.

```dart
await MyAds.instance.initialize(
  navigatorKey: navigatorKey,
  enableShowRateLogger: true,
);

// Truy cập bất cứ lúc nào:
print(MyAds.instance.showRate); // Map<adKey, ShowRateInfo>
```

---

## Loading overlay tuỳ chỉnh

Chọn style lúc init. Mặc định là 12 Lottie kèm theo package.

```dart
// Option 1: Lottie (mặc định + list tuỳ chỉnh)
fullScreenLoadingConfig: LottieLoadingConfig(
  lottiePaths: ['assets/lottie/spinner.json'],
  loadingText: 'Đang tải quảng cáo...',
  size: 200,
),

// Option 2: Video
fullScreenLoadingConfig: VideoLoadingConfig(
  path: 'assets/loading.mp4',
  type: VideoType.asset,
),

// Option 3: Widget tuỳ chỉnh
fullScreenLoadingConfig: WidgetLoadingConfig(
  loadingWidget: const Center(child: CircularProgressIndicator()),
),
```

---

## Throttle interstitial

Mặc định, `showInterstitialAd` bị throttle bởi `interIntervalInSeconds` (20s). Bỏ qua bằng `forceShow: true`.

```dart
// Cấu hình throttle:
await MyAds.instance.initialize(
  navigatorKey: navigatorKey,
  interIntervalInSeconds: 30,
);

// Ép bỏ qua throttle (vd. splash flow):
MyAds.instance.showInterstitialAd(
  context,
  adId: '...',
  forceShow: true,
);
```

---

## Bảng status

Giá trị `AdStatus` phát ra trên `events` và trên `stream` của từng controller:

| Status | Khi nào |
|---|---|
| `init` | Vừa tạo hoặc đã dispose |
| `loading` | `XxxAd.load(...)` đang chạy |
| `loaded` | SDK báo thành công |
| `loadFailed` | SDK báo thất bại |
| `shown` | Fullscreen ad đang trên màn |
| `impression` | Impression đầu hợp lệ |
| `clicked` | User click |
| `paid` | Paid event (doanh thu) |
| `dismiss` | User đóng ad |
| `showFailed` | Bước show thất bại |
| `earnReward` | Earn reward (chỉ rewarded) |
| `opened`, `closed` | Lifecycle banner/native |

Composite: `status.isShowOnScreen` = ad đang thực sự hiển thị (sau load, trước dismiss).

---

## License

MIT
