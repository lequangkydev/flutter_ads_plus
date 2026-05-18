// file: lib/src/native_inter_preload_util.dart
import 'dart:async';

import '../base_preload_event.dart';
import '../base_preload_protocol.dart';

class NativeInterPreloadUtil {
  NativeInterPreloadUtil._();

  static final PreloadProtocol _impl =
      MethodChannelPreloadProtocol('com.app.interstitial/preload');

  static Stream<BasePreloadEvent> get events => _impl.events;

  static Future<void> preload(
          {required String adUnitId, int bufferSize = 1}) async =>
      _impl.preload(adUnitId: adUnitId, bufferSize: bufferSize);

  static Future<bool> isAdAvailable(String adUnitId) async =>
      _impl.isAdAvailable(adUnitId);

  static Future<bool> show(String adUnitId) async => _impl.show(adUnitId);

  static Future<void> destroy({String? adUnitId}) async =>
      _impl.destroy(adUnitId: adUnitId);

  static Future<void> destroyAll() async => _impl.destroyAll();
}
