import "dart:convert";
import "package:oss_surveys_api/oss_surveys_api.dart" as SurveysApi;
import "package:oss_surveys_customer/database/dao/surveys_dao.dart";
import "package:oss_surveys_customer/database/database.dart";
import "package:oss_surveys_customer/main.dart";
import "package:oss_surveys_customer/mqtt/listeners/abstract_listener.dart";
import "package:oss_surveys_customer/mqtt/model/survey_message.dart";

/// MQTT Surveys Messages listener class
class SurveysListener extends AbstractMqttListener {
  SurveysListener() {
    setListeners();
  }

  @override
  String baseTopic = "oss/$environment/surveys";

  @override
  void handleCreate(String message) async {
    try {
      SurveysApi.SurveysApi surveysApi = await apiFactory.getSurveysApi();
      SurveysApi.Survey foundSurvey = await surveysApi
          .findSurvey(surveyId: _getSurveyIdFromMessage(message))
          .then((value) => value.data!);

      await surveysDao.createSurvey(foundSurvey);

      logger.info("Created new Survey with externalId ${foundSurvey.id}");
    } catch (e) {
      logger.shout("Couldn't handle create survey message ${e.toString()}");
    }
  }

  @override
  void handleUpdate(String message) async {
    try {
      SurveysApi.SurveysApi surveysApi = await apiFactory.getSurveysApi();
      SurveysApi.Survey foundSurvey = await surveysApi
          .findSurvey(surveyId: _getSurveyIdFromMessage(message))
          .then((value) => value.data!);

      await surveysDao.updateSurveyByExternalId(foundSurvey.id!, foundSurvey);

      logger.info("Updated Survey with externalId ${foundSurvey.id}");
    } catch (e) {
      logger.shout("Couldn't handle update survey message ${e.toString()}");
    }
  }

  @override
  void handleDelete(String message) async {
    try {
      String externalId = _getSurveyIdFromMessage(message);
      Survey? foundSurvey = await surveysDao.findSurveyByExternalId(externalId);

      if (foundSurvey == null) {
        logger.info("Couldn't find Survey with externalId $externalId");
      }

      await surveysDao.deleteSurvey(foundSurvey!.id);

      logger.info("Deleted Survey with externalId $externalId");
    } catch (e) {
      logger.shout("Couldn't handle update survey message ${e.toString()}");
    }
  }

  /// Gets Survey ID from [message]
  String _getSurveyIdFromMessage(String message) {
    return SurveyMessage.fromJson(jsonDecode(message)).id;
  }
}
