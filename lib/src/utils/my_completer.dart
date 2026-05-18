import 'dart:async';

class MyCompleter<T> {
  final Completer<T> _completer = Completer<T>();

  Future<T> get future => _completer.future;

  void complete([FutureOr<T>? value]) {
    if (isCompleted) {
      return;
    }
    _completer.complete(value);
  }

  void completeError(Object error, [StackTrace? stackTrace]) {
    if (isCompleted) {
      return;
    }
    _completer.completeError(error, stackTrace);
  }

  bool get isCompleted => _completer.isCompleted;
}
