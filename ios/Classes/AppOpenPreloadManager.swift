import Flutter
import GoogleMobileAds

class AppOpenPreloadManager: BaseAdPreloadManager<AppOpenAd>, FullScreenContentDelegate {

    var currentShowingId: String?

    init(messenger: FlutterBinaryMessenger) {
        super.init(messenger: messenger, channelName: "com.app.appopen/preload", tagLog: "AppOpenPreloadManager")
    }

    override func loadSdkAd(adUnitId: String, completion: @escaping (AppOpenAd?, Error?) -> Void) {
        let request = Request()
        // Đổi withAdUnitID thành with
        AppOpenAd.load(with: adUnitId, request: request) {
            ad, error in
            completion(ad, error)
        }
    }

    override func attachCallbacksAndShow(ad: AppOpenAd, adUnitId: String) {
        self.currentShowingId = adUnitId
        ad.fullScreenContentDelegate = self
        ad.paidEventHandler = {
            [weak self] adValue in
            let micros = adValue.value.multiplying(byPowerOf10: 6).int64Value
            self?.channel.invokeMethod("onPaidEvent", arguments: [
                "adUnitId": adUnitId,
                "valueMicros": micros,
                "currencyCode": adValue.currencyCode,
                "precisionType": adValue.precision.rawValue
            ])
        }

        // Đổi fromRootViewController thành from
        if let root = getRootViewController() {
            ad.present(from: root)
        }
    }

    // MARK: - FullScreenContentDelegate

    func adWillPresentFullScreenContent(_ ad: FullScreenPresentingAd) {
        if let id = currentShowingId {
            channel.invokeMethod("onAdShowed", arguments: ["adUnitId": id])
        }
    }

    func adDidDismissFullScreenContent(_ ad: FullScreenPresentingAd) {
        if let id = currentShowingId {
            channel.invokeMethod("onAdDismissed", arguments: ["adUnitId": id])
        }
    }

    func ad(_ ad: FullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) {
        if let id = currentShowingId {
            let nsError = error as NSError
            channel.invokeMethod("onAdFailedToShow", arguments: [
                "adUnitId": id, "code": nsError.code, "message": nsError.localizedDescription, "domain": nsError.domain
            ])
        }
    }
}