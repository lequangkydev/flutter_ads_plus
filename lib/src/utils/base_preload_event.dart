abstract class BasePreloadEvent {
  const BasePreloadEvent({required this.adUnitId});

  final String adUnitId;

  @override
  String toString() => '$runtimeType(adUnitId: $adUnitId)';
}

class AdPreloadedEvent extends BasePreloadEvent {
  const AdPreloadedEvent({
    required super.adUnitId,
    this.responseInfo,
  });

  final String? responseInfo;

  @override
  String toString() =>
      'AdPreloadedEvent(adUnitId: $adUnitId, responseInfo: $responseInfo)';
}

class AdsExhaustedEvent extends BasePreloadEvent {
  const AdsExhaustedEvent({required super.adUnitId});
}

class AdFailedToPreloadEvent extends BasePreloadEvent {
  const AdFailedToPreloadEvent({
    required super.adUnitId,
    required this.code,
    required this.message,
    required this.domain,
  });

  final int code;
  final String message;
  final String domain;

  @override
  String toString() =>
      'AdFailedToPreloadEvent(adUnitId: $adUnitId, code: $code, message: $message, domain: $domain)';
}

class AdShowedEvent extends BasePreloadEvent {
  const AdShowedEvent({required super.adUnitId});
}

class AdDismissedEvent extends BasePreloadEvent {
  const AdDismissedEvent({required super.adUnitId});
}

class AdFailedToShowEvent extends BasePreloadEvent {
  const AdFailedToShowEvent({
    required super.adUnitId,
    required this.code,
    required this.message,
    required this.domain,
  });

  final int code;
  final String message;
  final String domain;

  @override
  String toString() =>
      'AdFailedToShowEvent(adUnitId: $adUnitId, code: $code, message: $message, domain: $domain)';
}

class AdPaidEvent extends BasePreloadEvent {
  const AdPaidEvent({
    required super.adUnitId,
    required this.valueMicros,
    required this.currencyCode,
    required this.precisionType,
  });

  final int valueMicros;
  final String currencyCode;
  final int precisionType;

  double get value => valueMicros / 1000000.0;

  @override
  String toString() =>
      'AdPaidEvent(adUnitId: $adUnitId, value: $value $currencyCode, precisionType: $precisionType)';
}
