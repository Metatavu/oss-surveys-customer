import "package:drift/native.dart";
import "package:flutter_test/flutter_test.dart";
import "package:oss_surveys_customer/database/dao/surveys_dao.dart";
import "package:oss_surveys_customer/database/database.dart";
import "utils/test_utilities.dart";

void main() {
  late Database database;
  late SurveysDao surveysDao;

  setUp(() {
    database = Database(database: NativeDatabase.memory());
    surveysDao = SurveysDao(database);
  });

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
    await TestUtilities.waitFor(callback: () async {
      var newActiveSurvey = await surveysDao.findActiveSurvey();
      expect(newActiveSurvey, isNotNull);
      expect(newActiveSurvey!.title, "Should be published in 1 minute");
    });
  });
}
