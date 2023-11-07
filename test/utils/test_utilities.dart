import 'dart:async';

class TestUtilities {
  static Future<T?> waitFor<T>({
    Duration timeout = const Duration(minutes: 1),
    Duration cooldown = const Duration(milliseconds: 1000),
    required Future<T> Function() callback,
  }) async {
    DateTime start = DateTime.now();
    Completer<T> completer = Completer<T>();
    Timer.periodic(cooldown, (timer) async {
      try {
        if (DateTime.now().difference(start) > timeout) {
          timer.cancel();
          throw TimeoutException("Condition not met within $timeout");
        }

        return completer.complete(await callback());
      } catch (e) {
        if (e is TimeoutException) {
          completer.completeError(e);
        }
        print("Condition not met, waiting for $cooldown");
      }
    });

    return completer.future;
  }
}
