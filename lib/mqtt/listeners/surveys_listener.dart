import "dart:convert";
import "package:oss_surveys_api/oss_surveys_api.dart" as SurveysApi;
import "package:oss_surveys_customer/database/dao/surveys_dao.dart";
import "package:oss_surveys_customer/main.dart";
import "package:oss_surveys_customer/mqtt/listeners/abstract_listener.dart";
import "package:oss_surveys_customer/mqtt/model/device_survey_message.dart";
import "../../database/database.dart";

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
      SurveysApi.DeviceSurveysApi deviceSurveysApi =
          await apiFactory.getDeviceSurveysApi();
      SurveysApi.DeviceSurvey foundDeviceSurvey = await deviceSurveysApi
          .findDeviceSurvey(
              deviceId: _getSurveyIdFromMessage(message).deviceId,
              deviceSurveyId: _getSurveyIdFromMessage(message).deviceSurveyId)
          .then((value) => value.data!);

      SurveysApi.Survey foundSurvey = await surveysApi
          .findSurvey(surveyId: foundDeviceSurvey.surveyId)
          .then((value) => value.data!);

      await surveysDao.createSurvey(SurveysCompanion.insert(
          externalId: foundSurvey.id!,
          title: foundSurvey.title,
          publishStart: foundDeviceSurvey.publishStartTime!,
          publishEnd: foundDeviceSurvey.publishEndTime!,
          createdAt: foundSurvey.metadata!.createdAt!,
          modifiedAt: foundSurvey.metadata!.modifiedAt!,
          creatorId: foundSurvey.metadata!.creatorId!,
          lastModifierId: foundSurvey.metadata!.lastModifierId!));

      logger.info("Created new Survey with externalId ${foundSurvey.id}");
    } catch (e) {
      logger.shout("Couldn't handle create survey message ${e.toString()}");
    }
  }

// TODO: Methods below to update as above
  @override
  void handleUpdate(String message) async {
    try {
      SurveysApi.SurveysApi surveysApi = await apiFactory.getSurveysApi();
      SurveysApi.Survey foundSurvey = await surveysApi
          .findSurvey(surveyId: _getSurveyIdFromMessage(message).surveyId)
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
      String externalId = _getSurveyIdFromMessage(message).surveyId;
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
  DeviceSurveyMessage _getSurveyIdFromMessage(String message) {
    return DeviceSurveyMessage.fromJson(jsonDecode(message));
  }
}
