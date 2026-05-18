import UIKit
import Flutter
import google_mobile_ads

@main
@objc class AppDelegate: FlutterAppDelegate {
    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        GeneratedPluginRegistrant.register(with: self)
        registerNativeAdFactories()
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }

    /// Register every NativeAdFactory used by the Dart `AdFactory` enum.
    /// Đăng ký mọi NativeAdFactory mà Dart enum `AdFactory` dùng.
    private func registerNativeAdFactories() {
        // Normal layout (full layout, button at top or bottom).
        // Layout chuẩn (full layout, button trên hoặc dưới).
        FLTGoogleMobileAdsPlugin.registerNativeAdFactory(
            self,
            factoryId: "topNormalNativeAd",
            nativeAdFactory: NormalNativeAdFactory(buttonPosition: .top))

        FLTGoogleMobileAdsPlugin.registerNativeAdFactory(
            self,
            factoryId: "bottomNormalNativeAd",
            nativeAdFactory: NormalNativeAdFactory(buttonPosition: .bottom))

        // Extra layout — reuse Normal in this example. Add a dedicated
        // factory if you want different visuals.
        // Layout Extra — tái dùng Normal trong example này. Thêm factory
        // riêng nếu cần UI khác.
        FLTGoogleMobileAdsPlugin.registerNativeAdFactory(
            self,
            factoryId: "topExtraNativeAd",
            nativeAdFactory: NormalNativeAdFactory(buttonPosition: .top))

        FLTGoogleMobileAdsPlugin.registerNativeAdFactory(
            self,
            factoryId: "bottomExtraNativeAd",
            nativeAdFactory: NormalNativeAdFactory(buttonPosition: .bottom))

        // Home layout (compact horizontal: media + text column).
        // Layout Home (ngang compact: media + cột text).
        FLTGoogleMobileAdsPlugin.registerNativeAdFactory(
            self,
            factoryId: "homeNativeAd",
            nativeAdFactory: HomeNativeAdFactory())

        // Small layout (single row: icon + text + button).
        // Layout Small (1 hàng: icon + text + button).
        FLTGoogleMobileAdsPlugin.registerNativeAdFactory(
            self,
            factoryId: "smallNativeAd",
            nativeAdFactory: SmallNativeAdFactory())

        // Full layout (fullscreen, dark background — overlay on app-open).
        // Layout Full (full-màn, nền tối — phủ lên app-open).
        FLTGoogleMobileAdsPlugin.registerNativeAdFactory(
            self,
            factoryId: "fullNativeAd",
            nativeAdFactory: FullNativeAdFactory())
    }
}
