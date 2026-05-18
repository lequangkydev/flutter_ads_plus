import 'dart:async';

import 'package:flutter/services.dart';

import 'base_preload_event.dart';

/// Contract between Dart and the native preload pipeline. Each ad
/// format owns its own implementation (one method channel each).
///
/// Hợp đồng giữa Dart và pipeline preload native. Mỗi ad format có
/// implementation riêng (mỗi cái 1 method channel).
abstract class PreloadProtocol {
  Future<void> preload({required String adUnitId, int bufferSize = 1});

  Future<bool> isAdAvailable(String adUnitId);

  Future<bool> show(String adUnitId);

  Future<void> destroy({String? adUnitId});

  Future<void> destroyAll();

  Stream<BasePreloadEvent> get events;

  void dispose();
}

/// MethodChannel-based [PreloadProtocol] implementation. Forwards Dart
/// requests to the matching native preload manager
/// (`com.app.interstitial/preload`, `com.app.appopen/preload`) and
/// re-emits the inbound platform callbacks as [BasePreloadEvent]
/// instances on [events].
///
/// Implementation [PreloadProtocol] dựa trên MethodChannel. Forward
/// request từ Dart sang preload manager native tương ứng
/// (`com.app.interstitial/preload`, `com.app.appopen/preload`) và phát
/// lại callback từ platform thành [BasePreloadEvent] trên [events].
class MethodChannelPreloadProtocol implements PreloadProtocol {
  MethodChannelPreloadProtocol(this.channelName) {
    _channel = MethodChannel(channelName);
    _ensureHandler();
  }

  final String channelName;
  late final MethodChannel _channel;
  bool _handlerSet = false;

  final Set<String> _startedAdUnitIds = <String>{};
  final StreamController<BasePreloadEvent> _eventsController =
      StreamController<BasePreloadEvent>.broadcast();

  @override
  Stream<BasePreloadEvent> get events => _eventsController.stream;

  @override
  Future<void> preload({required String adUnitId, int bufferSize = 1}) async {
    if (_startedAdUnitIds.contains(adUnitId)) return;
    try {
      await _channel.invokeMethod('startPreload', {
        'adUnitId': adUnitId,
        'bufferSize': bufferSize,
      });
      _startedAdUnitIds.add(adUnitId);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<bool> isAdAvailable(String adUnitId) async {
    try {
      final result = await _channel
          .invokeMethod<bool>('isAdAvailable', {'adUnitId': adUnitId});
      return result ?? false;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<bool> show(String adUnitId) async {
    try {
      final result =
          await _channel.invokeMethod<bool>('show', {'adUnitId': adUnitId});
      return result ?? false;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<void> destroy({String? adUnitId}) async {
    await _channel.invokeMethod('destroy', {
      if (adUnitId != null) 'adUnitId': adUnitId,
    });
    if (adUnitId != null) _startedAdUnitIds.remove(adUnitId);
  }

  @override
  Future<void> destroyAll() async {
    await _channel.invokeMethod('destroyAll');
    _startedAdUnitIds.clear();
  }

  @override
  void dispose() {
    _eventsController.close();
    _channel.setMethodCallHandler(null);
    _handlerSet = false;
    _startedAdUnitIds.clear();
  }

  void _ensureHandler() {
    if (_handlerSet) return;
    _handlerSet = true;

    _channel.setMethodCallHandler((call) async {
      final args = (call.arguments as Map?)?.cast<String, dynamic>() ??
          <String, dynamic>{};
      final adUnitId = args['adUnitId'] as String? ?? '';

      switch (call.method) {
        case 'onPaidEvent':
          _eventsController.add(AdPaidEvent(
            adUnitId: adUnitId,
            valueMicros: args['valueMicros'] as int? ?? 0,
            currencyCode: args['currencyCode'] as String? ?? '',
            precisionType: args['precisionType'] as int? ?? 0,
          ));
          break;
        case 'onAdPreloaded':
          _eventsController.add(AdPreloadedEvent(
              adUnitId: adUnitId,
              responseInfo: args['responseInfo'] as String?));
          break;
        case 'onAdsExhausted':
          _eventsController.add(AdsExhaustedEvent(adUnitId: adUnitId));
          break;
        case 'onAdFailedToPreload':
          _eventsController.add(AdFailedToPreloadEvent(
            adUnitId: adUnitId,
            code: args['code'] as int? ?? 0,
            message: args['message'] as String? ?? '',
            domain: args['domain'] as String? ?? '',
          ));
          break;
        case 'onAdShowed':
          _eventsController.add(AdShowedEvent(adUnitId: adUnitId));
          break;
        case 'onAdDismissed':
          _eventsController.add(AdDismissedEvent(adUnitId: adUnitId));
          break;
        case 'onAdFailedToShow':
          _eventsController.add(AdFailedToShowEvent(
            adUnitId: adUnitId,
            code: args['code'] as int? ?? 0,
            message: args['message'] as String? ?? '',
            domain: args['domain'] as String? ?? '',
          ));
          break;
      }
    });
  }
}
