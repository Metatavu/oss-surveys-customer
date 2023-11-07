import "dart:async";

import "package:clock/clock.dart";
import "package:drift/native.dart";
import "package:flutter_test/flutter_test.dart";
import "package:oss_surveys_customer/database/dao/surveys_dao.dart";
import "package:oss_surveys_customer/database/database.dart";

void main() {
  late Database database;
  late SurveysDao surveysDao;

  setUp(() {
    database = Database(database: NativeDatabase.memory());
    surveysDao = SurveysDao(database);
  });
  // tearDown(() async => await database.close());

  Future<T?> waitFor<T>({
    Duration timeout = const Duration(minutes: 1),
    Duration cooldown = const Duration(milliseconds: 1000),
    required Future<T> Function() callback,
  }) async {
    T? result;
    DateTime start = DateTime.now();
    Completer<T> completer = Completer<T>();
    Timer.periodic(cooldown, (timer) async {
      try {
        if (DateTime.now().difference(start) > timeout) {
          timer.cancel();
          throw TimeoutException("Condition not met within $timeout");
        }
        result = await callback();
        if (result != null) {
          completer.complete(result);
        }
      } catch (e) {
        if (e is TimeoutException) {
          completer.completeError(e);
        }
        print("Condition not met, waiting for $cooldown");
      }
    });

    return completer.future;
  }

  test("Should select correct survey as active", () async {
    final now = DateTime.now();

    await surveysDao.createSurvey(
      externalId: "8ca5b52a-af85-4be1-a7f1-e56589db60e1",
      title: "Should be published",
      timeout: 10,
      modifiedAt: now,
    );
    await surveysDao.createSurvey(
      externalId: "bfa63619-1f91-4fca-bfe8-cd37752c9385",
      title: "Should be published in 1 minute",
      timeout: 10,
      modifiedAt: now,
      publishStart: now.add(const Duration(seconds: 30)),
    );
    var surveys = await surveysDao.listSurveys();
    var activeSurvey = await surveysDao.findActiveSurvey();

    expect(surveys.length, 2);
    expect(activeSurvey, isNotNull);
    expect(activeSurvey!.title, "Should be published");
    await waitFor(callback: () async {
      var newActiveSurvey = await surveysDao.findActiveSurvey();
      expect(newActiveSurvey, isNotNull);
      expect(newActiveSurvey!.title, "Should be published in 1 minute");
    });
  });
}
