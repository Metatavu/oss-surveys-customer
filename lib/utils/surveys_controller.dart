import "package:drift/drift.dart";
import "package:oss_surveys_customer/database/dao/surveys_dao.dart";
import "package:oss_surveys_customer/database/database.dart" as database;
import "package:oss_surveys_api/oss_surveys_api.dart" as surveys_api;
import "package:oss_surveys_customer/main.dart";
import "package:oss_surveys_customer/utils/pages_controller.dart";
import "package:simple_logger/simple_logger.dart";
import "../database/dao/pages_dao.dart";
import "package:oss_surveys_customer/database/database.dart";

/// Surveys Controller class
class SurveysController {
  /// Persists [newSurvey]
  Future<database.Survey> persistSurvey(
      surveys_api.DeviceSurveyData newSurvey) async {
    database.Survey? existingSurvey =
        await surveysDao.findSurveyByExternalId(newSurvey.id!);

    if (existingSurvey == null) {
      SimpleLogger()
          .info("Persisting new survey ${newSurvey.title} ${newSurvey.id}");
      database.Survey createdSurvey = await surveysDao.createSurvey(
        database.SurveysCompanion.insert(
          externalId: newSurvey.id!,
          title: newSurvey.title!,
          publishStart: Value(newSurvey.publishStartTime),
          publishEnd: Value(newSurvey.publishEndTime),
          timeout: newSurvey.timeout!,
          modifiedAt: newSurvey.metadata!.modifiedAt!,
        ),
      );

      await _handlePages(newSurvey.pages?.toList(), createdSurvey.id);

      return createdSurvey;
    } else {
      SimpleLogger().info(
        "Survey with id ${newSurvey.id} already exists, checking if updated...",
      );
      database.Survey updatedSurvey = existingSurvey;
      if (_compareSurveys(existingSurvey, newSurvey)) {
        SimpleLogger()
            .info("Survey with id ${newSurvey.id} is updated, updating...");
        updatedSurvey =
            await surveysDao.updateSurvey(existingSurvey, newSurvey);
        await _handlePages(newSurvey.pages?.toList(), updatedSurvey.id);
      }

      return updatedSurvey;
    }
  }

  /// Lists all surveys from local database
  Future<List<Survey>> listSurveys() async {
    return surveysDao.listSurveys();
  }

  /// Deletes Survey and associated pages by [externalId]
  Future deleteSurvey(String externalId) async {
    database.Survey? foundSurvey =
        await surveysDao.findSurveyByExternalId(externalId);

    if (foundSurvey != null) {
      await pagesController.deletePagesBySurveyId(foundSurvey.id);
      await surveysDao.deleteSurvey(foundSurvey.id);
      SimpleLogger().info(
        "Deleted Survey ${foundSurvey.title} ${foundSurvey.externalId}",
      );
    }
  }

  /// Handles Survey [pages]
  Future _handlePages(
    List<surveys_api.DeviceSurveyPageData>? pages,
    int surveyId,
  ) async {
    if (pages != null) {
      List<database.Page> existingPages = await pagesDao.listPagesBySurveyId(
        surveyId,
      );
      existingPages.retainWhere((existingPage) => !pages
          .map((page) => page.id)
          .toList()
          .contains(existingPage.externalId));

      for (var page in existingPages) {
        await pagesDao.deletePage(page.id);
      }
      for (var page in pages) {
        await pagesController.persistPage(page, surveyId);
      }
    }
  }

  /// Compares if [survey] is different from persisted Survey
  bool _compareSurveys(
          database.Survey survey, surveys_api.DeviceSurveyData newSurvey) =>
      survey.modifiedAt.isBefore(newSurvey.metadata!.modifiedAt!);
}

final surveysController = SurveysController();
