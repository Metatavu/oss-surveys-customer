import "dart:convert";
import "package:oss_surveys_api/oss_surveys_api.dart" as surveys_api;
import "package:oss_surveys_customer/database/dao/surveys_dao.dart";
import "package:oss_surveys_customer/database/database.dart" as database;
import "package:oss_surveys_customer/main.dart";
import "package:oss_surveys_customer/mqtt/listeners/abstract_listener.dart";
import "package:oss_surveys_customer/mqtt/model/device_survey_message.dart";
import "../../database/dao/pages_dao.dart";
import "../../utils/pages_controller.dart";

/// MQTT Surveys Messages listener class
class SurveysListener extends AbstractMqttListener<DeviceSurveyMessage> {
  SurveysListener() {
    setListeners();
  }

  @override
  void handleCreate(String message) async {
    try {
      DeviceSurveyMessage deserializedMessage = deserializeMessage(message);
      surveys_api.DeviceDataApi deviceDataApi =
          await apiFactory.getDeviceDataApi();
      surveys_api.DeviceSurveyData? deviceSurveyData = await deviceDataApi
          .findDeviceDataSurvey(
            deviceId: deserializedMessage.deviceId,
            deviceSurveyId: deserializedMessage.deviceSurveyId,
          )
          .then((value) => value.data);

      if (deviceSurveyData != null) {
        database.Survey? existingSurvey =
            await surveysDao.findSurveyByExternalId(deviceSurveyData.surveyId!);

        if (existingSurvey != null) {
          logger.info(
              "Survey with id ${deviceSurveyData.surveyId} already exists, replacing...");
          List<database.Page> existingPages =
              await pagesDao.listPagesBySurveyId(existingSurvey.id);
          for (var page in existingPages) {
            await pagesDao.deletePage(page.id);
          }
          await surveysDao.deleteSurvey(existingSurvey.id);
        }

        database.Survey persistedSurvey = await surveysDao.createSurvey(
          database.SurveysCompanion.insert(
            externalId: deviceSurveyData.surveyId!,
            title: deviceSurveyData.title!,
            timeout: deviceSurveyData.timeout!,
            modifiedAt: deviceSurveyData.metadata!.modifiedAt!,
          ),
        );
        if (deviceSurveyData.pages != null) {
          for (var page in deviceSurveyData.pages!) {
            await pagesController.persistPage(page, persistedSurvey.id);
          }
        }
        logger.info(
          "Created new Survey ${deviceSurveyData.title} with externalId ${deviceSurveyData.surveyId}",
        );
      }
    } catch (e) {
      logger.shout("Couldn't handle create survey message ${e.toString()}");
    }
  }

  /// TODO: Implement this in later task
  @override
  void handleUpdate(String message) async {
    try {
      logger.info("Updated Survey with externalId");
    } catch (e) {
      logger.shout("Couldn't handle update survey message ${e.toString()}");
    }
  }

  /// TODO: Implement this in later task
  @override
  void handleDelete(String message) async {
    try {
      logger.info("Deleted Survey with externalId");
    } catch (e) {
      logger.shout("Couldn't handle update survey message ${e.toString()}");
    }
  }

  @override
  DeviceSurveyMessage deserializeMessage(String message) =>
      DeviceSurveyMessage.fromJson(jsonDecode(message));
}
