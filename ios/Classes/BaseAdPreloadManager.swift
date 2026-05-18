import Flutter
import UIKit
import GoogleMobileAds

open class BaseAdPreloadManager<T: AnyObject>: NSObject {
    public let channel: FlutterMethodChannel
    public let tagLog: String

    // Lưu trữ quảng cáo đã sẵn sàng
    private var adBuffer: [String: [T]] = [:]
    // Lưu trữ target size cấu hình từ Flutter
    private var bufferSizes: [String: Int] = [:]
    // Đếm số lượng request đang được tải để tránh việc spam load
    private var loadingCounts: [String: Int] = [:]

    // ĐẾM: Số lượng quảng cáo đã được lấy ra để hiển thị (đã sử dụng)
    private var usedCounts: [String: Int] = [:]

    public init(messenger: FlutterBinaryMessenger, channelName: String, tagLog: String) {
        self.channel = FlutterMethodChannel(name: channelName, binaryMessenger: messenger)
        self.tagLog = tagLog
        super.init()
        self.channel.setMethodCallHandler(self.handle)
    }

    // MARK: - Hàm in Log trạng thái Buffer
    private func logBufferStatus(adUnitId: String, context: String) {
        let targetSize = bufferSizes[adUnitId] ?? 0
        let ready = adBuffer[adUnitId]?.count ?? 0
        let loading = loadingCounts[adUnitId] ?? 0
        let used = usedCounts[adUnitId] ?? 0

        print("[\(tagLog)] 📊 [\(context)] AdUnit: \(adUnitId) | Đã sử dụng: \(used) | Đã load (sẵn sàng): \(ready)/\(targetSize) | Đang load bù: \(loading)")
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        let args = call.arguments as? [String: Any]
        let adUnitId = args?["adUnitId"] as? String ?? ""

        switch call.method {
        case "startPreload":
            let bufferSize = args?["bufferSize"] as? Int ?? 1
            if adUnitId.isEmpty {
                result(FlutterError(code: "INVALID_AD_UNIT", message: "adUnitId is empty", details: nil))
                return
            }
            // Lưu lại size mục tiêu và bắt đầu bơm đầy buffer
            bufferSizes[adUnitId] = bufferSize
            print("[\(tagLog)] 🚀 BẮT ĐẦU PRELOAD AdUnit: \(adUnitId) với BufferSize: \(bufferSize)")
            replenishBuffer(adUnitId: adUnitId)
            result(nil)

        case "show":
            if adUnitId.isEmpty {
                result(FlutterError(code: "INVALID_AD_UNIT", message: "adUnitId is empty", details: nil))
                return
            }
            showPreloadedAdInternal(adUnitId: adUnitId, result: result)

        case "isAdAvailable":
            result(checkIsAdAvailable(adUnitId: adUnitId))

        case "destroy":
            destroyAd(adUnitId: adUnitId)
            result(nil)

        case "destroyAll":
            destroyAllAds()
            result(nil)

        default:
            result(FlutterMethodNotImplemented)
        }
    }

    // MARK: - Logic Preload cốt lõi
    private func replenishBuffer(adUnitId: String) {
        let targetSize = bufferSizes[adUnitId] ?? 1
        let currentReady = adBuffer[adUnitId]?.count ?? 0
        let currentlyLoading = loadingCounts[adUnitId] ?? 0

        let needed = targetSize - (currentReady + currentlyLoading)

        if needed > 0 {
            for _ in 0..<needed {
                loadingCounts[adUnitId] = (loadingCounts[adUnitId] ?? 0) + 1
                self.logBufferStatus(adUnitId: adUnitId, context: "Bắt đầu tải thêm")

                loadSdkAd(adUnitId: adUnitId) { [weak self] ad, error in
                    guard let self = self else { return }
                    self.loadingCounts[adUnitId] = max(0, (self.loadingCounts[adUnitId] ?? 1) - 1)

                    if let error = error {
                        let nsError = error as NSError
                        print("[\(self.tagLog)] ❌ Lỗi tải quảng cáo \(adUnitId): \(nsError.localizedDescription)")

                        self.channel.invokeMethod("onAdFailedToPreload", arguments: [
                            "adUnitId": adUnitId,
                            "code": nsError.code,
                            "message": nsError.localizedDescription,
                            "domain": nsError.domain
                        ])
                        self.logBufferStatus(adUnitId: adUnitId, context: "Tải thất bại")
                    } else if let ad = ad {
                        var queue = self.adBuffer[adUnitId] ?? []
                        queue.append(ad)
                        self.adBuffer[adUnitId] = queue

                        self.channel.invokeMethod("onAdPreloaded", arguments: ["adUnitId": adUnitId, "responseInfo": ""])
                        self.logBufferStatus(adUnitId: adUnitId, context: "Tải thành công")

                        // Kích hoạt lại để đảm bảo lấp đầy nếu target bị thay đổi
                        self.replenishBuffer(adUnitId: adUnitId)
                    }
                }
            }
        }
    }

    private func showPreloadedAdInternal(adUnitId: String, result: @escaping FlutterResult) {
        if !checkIsAdAvailable(adUnitId: adUnitId) {
            print("[\(tagLog)] ⚠️ Không có sẵn quảng cáo để show: \(adUnitId)")
            self.channel.invokeMethod("onAdsExhausted", arguments: ["adUnitId": adUnitId])
            result(false)
            return
        }

        guard let ad = pollSdkAd(adUnitId: adUnitId) else {
            self.channel.invokeMethod("onAdsExhausted", arguments: ["adUnitId": adUnitId])
            result(false)
            return
        }

        attachCallbacksAndShow(ad: ad, adUnitId: adUnitId)
        result(true)
    }

    public func checkIsAdAvailable(adUnitId: String) -> Bool {
        return (adBuffer[adUnitId]?.count ?? 0) > 0
    }

    // MARK: - Poll Ad & Tự động nạp lại (Auto-refill)
    private func pollSdkAd(adUnitId: String) -> T? {
        if var queue = adBuffer[adUnitId], !queue.isEmpty {
            let ad = queue.removeFirst()
            adBuffer[adUnitId] = queue

            // Tăng số lượng đã dùng
            usedCounts[adUnitId] = (usedCounts[adUnitId] ?? 0) + 1
            self.logBufferStatus(adUnitId: adUnitId, context: "Lấy quảng cáo ra hiển thị")

            // Kích hoạt nạp bù
            replenishBuffer(adUnitId: adUnitId)

            return ad
        }
        return nil
    }

    private func destroyAd(adUnitId: String) {
        adBuffer.removeValue(forKey: adUnitId)
        bufferSizes.removeValue(forKey: adUnitId)
        loadingCounts.removeValue(forKey: adUnitId)
        usedCounts.removeValue(forKey: adUnitId)
        print("[\(tagLog)] 🗑️ Đã hủy AdUnit: \(adUnitId)")
    }

    private func destroyAllAds() {
        adBuffer.removeAll()
        bufferSizes.removeAll()
        loadingCounts.removeAll()
        usedCounts.removeAll()
        print("[\(tagLog)] 🗑️ Đã hủy TOÀN BỘ quảng cáo")
    }

    // Các hàm để Override
    open func loadSdkAd(adUnitId: String, completion: @escaping (T?, Error?) -> Void) {}
    open func attachCallbacksAndShow(ad: T, adUnitId: String) {}

    public func getRootViewController() -> UIViewController? {
        let keyWindow = UIApplication.shared.windows.first { $0.isKeyWindow }
        var root = keyWindow?.rootViewController
        while let presented = root?.presentedViewController { root = presented }
        return root
    }
}