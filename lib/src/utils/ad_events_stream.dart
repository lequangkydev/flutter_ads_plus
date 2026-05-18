import 'dart:async';

import 'package:flutter_ads_plus/flutter_ads_plus.dart';

class AdInformation {
  AdInformation({
    required this.status,
    required this.type,
    this.error,
    required this.adId,
    this.adKey,
    this.valueMicros,
    this.precision,
    this.currencyCode,
  });

  final AdStatus status;
  final AdType type;
  final AdError? error;
  final String adId;
  final String? adKey;

  //Properties for paid event
  final double? valueMicros;
  final PrecisionType? precision;
  final String? currencyCode;
}

class AdEventsStream {
  AdEventsStream._();

  static final AdEventsStream instance = AdEventsStream._();
  final StreamController<AdInformation> _controller =
      StreamController.broadcast();

  Stream<AdInformation> get stream => _controller.stream;

  void addEvent(AdInformation event) {
    _controller.add(event);
  }
}
