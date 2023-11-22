import 'dart:async';

class TestUtilities {
  static Future<T?> waitFor<T>({
    int cooldown = 1,
    int timeout = 1,
    required Future<T> Function() callback,
  }) async {
    DateTime start = DateTime.now();
    Completer<T> completer = Completer<T>();
    Timer.periodic(Duration(seconds: cooldown), (timer) async {
      try {
        if (DateTime.now().difference(start) > Duration(minutes: timeout)) {
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
