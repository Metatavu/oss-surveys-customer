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

  tearDown(() async {
    await database.close();
  });

  test("Should update active survey", () async {
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

      return newActiveSurvey;
    });
  });

  test("Not active if publishEnd is in the past", () async {
    final now = DateTime.now();
    final yesterday = now.subtract(const Duration(days: 1));

    await surveysDao.createSurvey(
      externalId: "1cf210b9-53ca-4acb-a1f3-e8c2038cfcf0",
      title: "Should be published",
      timeout: 10,
      modifiedAt: now,
    );
    await surveysDao.createSurvey(
      externalId: "9953d35a-5bdc-4c9e-ba36-84d368bcb425",
      title: "Should not be published",
      timeout: 10,
      modifiedAt: now,
      publishEnd: yesterday,
    );
    var surveys = await surveysDao.listSurveys();
    var activeSurvey = await surveysDao.findActiveSurvey();

    expect(surveys.length, 2);
    expect(activeSurvey, isNotNull);
    expect(activeSurvey!.title, "Should be published");
  });

  test("Survey is no longer active after publishEnd date", () async {
    final now = DateTime.now();

    await surveysDao.createSurvey(
      externalId: "9157cb8b-49de-4422-8b07-9f282ee8e7b5",
      title: "Should be published and then not published",
      timeout: 10,
      modifiedAt: now,
      publishEnd: now.add(const Duration(seconds: 5)),
    );

    var surveys = await surveysDao.listSurveys();
    var activeSurvey = await surveysDao.findActiveSurvey();

    expect(surveys.length, 1);
    expect(activeSurvey, isNotNull);
    expect(activeSurvey!.title, "Should be published and then not published");

    await TestUtilities.waitFor(callback: () async {
      var newActiveSurvey = await surveysDao.findActiveSurvey();
      expect(newActiveSurvey, isNull);
    });
  });
}
