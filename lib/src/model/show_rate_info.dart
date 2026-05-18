class ShowRateInfo {
  ShowRateInfo({
    this.request = 0,
    this.impression = 0,
    this.showRate = 0,
    this.adId = '',
  });

  int request;
  int impression;
  double showRate;
  String adId;

  @override
  String toString() {
    return 'ShowRateInfo{request: $request, impression: $impression, showRate: ${showRate * 100}%, adId: $adId}';
  }
}
