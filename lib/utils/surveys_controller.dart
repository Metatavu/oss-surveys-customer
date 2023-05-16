import 'package:drift/drift.dart';
import 'package:oss_surveys_customer/database/dao/surveys_dao.dart';
import 'package:oss_surveys_customer/database/database.dart';
import "package:oss_surveys_api/oss_surveys_api.dart" as surveys_api;
import 'package:oss_surveys_customer/main.dart';
import 'package:oss_surveys_customer/utils/pages_controller.dart';

/// Surveys Controller class
class SurveysController {
  /// Persists [newSurvey]
  Future<Survey> persistSurvey(surveys_api.DeviceSurveyData newSurvey) async {
    Survey? existingSurvey =
        await surveysDao.findSurveyByExternalId(newSurvey.id!);

    if (existingSurvey == null) {
      logger.info("Persisting new survey ${newSurvey.title} ${newSurvey.id}");
      Survey createdSurvey = await surveysDao.createSurvey(
        SurveysCompanion.insert(
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
      logger.info(
        "Survey with id ${newSurvey.id} already exists, checking if updated...",
      );
      Survey updatedSurvey = existingSurvey;
      if (_compareSurveys(existingSurvey, newSurvey)) {
        logger.info("Survey with id ${newSurvey.id} is updated, updating...");
        updatedSurvey =
            await surveysDao.updateSurvey(existingSurvey, newSurvey);
        await _handlePages(newSurvey.pages?.toList(), existingSurvey.id);
      }

      return updatedSurvey;
    }
  }

  /// Deletes Survey and associated pages by [externalId]
  Future deleteSurvey(String externalId) async {
    Survey? foundSurvey = await surveysDao.findSurveyByExternalId(externalId);

    if (foundSurvey != null) {
      await pagesController.deletePagesBySurveyId(foundSurvey.id);
      await surveysDao.deleteSurvey(foundSurvey.id);
      logger.info(
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
      for (var page in pages) {
        await pagesController.persistPage(page, surveyId);
      }
    }
  }

  /// Compares if [survey] is different from persisted Survey
  bool _compareSurveys(Survey survey, surveys_api.DeviceSurveyData newSurvey) =>
      survey.modifiedAt.isBefore(newSurvey.metadata!.modifiedAt!);
}

final surveysController = SurveysController();
