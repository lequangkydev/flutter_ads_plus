import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

final logger = MyLogger.instance;

class MyLogger extends Logger {
  MyLogger._()
      : super(
          filter: MyFilter(),
          printer: PrettyPrinter(),
        );

  static final MyLogger instance = MyLogger._();
}

class MyFilter extends LogFilter {
  @override
  bool shouldLog(LogEvent event) {
    return kDebugMode;
  }
}
