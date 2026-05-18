import Flutter
import UIKit

public class FlutterAdsPlugin: NSObject, FlutterPlugin {
    var appOpenManager: AppOpenPreloadManager?
    var interstitialManager: InterstitialPreloadManager?

    public static func register(with registrar: FlutterPluginRegistrar) {
        let instance = FlutterAdsPlugin()

        // Khởi tạo các Manager
        instance.appOpenManager = AppOpenPreloadManager(messenger: registrar.messenger())
        instance.interstitialManager = InterstitialPreloadManager(messenger: registrar.messenger())

        registrar.publish(instance)
    }
}