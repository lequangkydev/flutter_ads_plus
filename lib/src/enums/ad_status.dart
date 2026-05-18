/// Status of an ad through its lifetime, as broadcast by an
/// [AdController] / via [MyAds.events].
///
/// Trạng thái của ad theo vòng đời, được broadcast bởi [AdController] /
/// qua [MyAds.events].
enum AdStatus {
  /// Created but not loading yet, or freshly disposed.
  /// Đã khởi tạo nhưng chưa load, hoặc vừa dispose xong.
  init,

  /// `XxxAd.load(...)` in flight. / Đang `XxxAd.load(...)`.
  loading,

  /// SDK reported a successful load; the ad reference is ready to show.
  /// SDK báo load thành công; ad reference sẵn sàng show.
  loaded,

  /// SDK reported a load failure. / SDK báo load failed.
  loadFailed,

  /// SDK reported `onAdShowedFullScreenContent` (fullscreen ads only).
  /// SDK báo `onAdShowedFullScreenContent` (chỉ fullscreen).
  shown,

  /// `onAdClosed` was called. / `onAdClosed` được gọi.
  closed,

  /// `onAdOpened` was called. / `onAdOpened` được gọi.
  opened,

  /// Paid event arrived; revenue available in [AdInformation.valueMicros].
  /// Paid event đến; doanh thu có ở [AdInformation.valueMicros].
  paid,

  /// `onAdDismissedFullScreenContent` was called. / `onAdDismissedFullScreenContent` được gọi.
  dismiss,

  /// Show step failed after a successful load.
  /// Bước show failed sau khi load đã thành công.
  showFailed,

  /// User clicked the ad. / User click vào ad.
  clicked,

  /// First valid impression confirmed by the SDK.
  /// Impression đầu hợp lệ được SDK xác nhận.
  impression,

  /// User earned the reward (rewarded ads only).
  /// User earn reward (chỉ rewarded).
  earnReward,
}

extension AdStatusExtension on AdStatus {
  bool get isInit => this == AdStatus.init;

  bool get isLoading => this == AdStatus.loading;

  bool get isLoaded => this == AdStatus.loaded;

  bool get isLoadFailed => this == AdStatus.loadFailed;

  bool get isShown => this == AdStatus.shown;

  bool get isClosed => this == AdStatus.closed;

  bool get isOpened => this == AdStatus.opened;

  bool get isPaid => this == AdStatus.paid;

  bool get isDismiss => this == AdStatus.dismiss;

  bool get isShowFailed => this == AdStatus.showFailed;

  bool get isClicked => this == AdStatus.clicked;

  bool get isImpression => this == AdStatus.impression;

  bool get isEarnReward => this == AdStatus.earnReward;

  /// Composite — `true` when the ad is in a state where its widget
  /// should actually be rendered on screen (i.e. anything after the
  /// successful load that isn't a load failure).
  ///
  /// Tổng hợp — `true` khi ad đang ở trạng thái mà widget nên thực sự
  /// render trên màn (sau khi load thành công, chưa bị load fail).
  bool get isShowOnScreen =>
      isLoaded ||
      isPaid ||
      isOpened ||
      isClosed ||
      isClicked ||
      isImpression ||
      isShown;
}
