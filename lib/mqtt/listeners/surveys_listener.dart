import "dart:convert";
import "package:oss_surveys_api/oss_surveys_api.dart" as surveys_api;
import "package:oss_surveys_customer/main.dart";
import "package:oss_surveys_customer/mqtt/listeners/abstract_listener.dart";
import "package:oss_surveys_customer/mqtt/model/device_survey_message.dart";
import "package:oss_surveys_customer/utils/surveys_controller.dart";

/// MQTT Surveys Messages listener class
class SurveysListener extends AbstractMqttListener<DeviceSurveyMessage> {
  SurveysListener() {
    setListeners();
  }

  @override
  void handleCreate(String message) async {
    logger.info("Handling create survey message");
    try {
      surveys_api.DeviceSurveyData? deviceSurveyData =
          await _findDeviceSurveyData(message);
      if (deviceSurveyData != null) {
        surveysController
            .persistSurvey(deviceSurveyData)
            .then((value) => streamController.sink.add(value));
      }
    } catch (e) {
      logger.shout("Couldn't handle create survey message ${e.toString()}");
    }
  }

  @override
  void handleUpdate(String message) async {
    logger.info("Handling update survey message");
    try {
      surveys_api.DeviceSurveyData? deviceSurveyData =
          await _findDeviceSurveyData(message);

      if (deviceSurveyData != null) {
        surveysController
            .persistSurvey(deviceSurveyData)
            .then((value) => streamController.sink.add(value));
      }
    } catch (e) {
      logger.shout("Couldn't handle update survey message ${e.toString()}");
    }
  }

  @override
  void handleDelete(String message) async {
    logger.info("Handling delete survey message");
    try {
      DeviceSurveyMessage deserializedMessage = deserializeMessage(message);
      surveysController
          .deleteSurvey(deserializedMessage.deviceSurveyId)
          .then((_) => streamController.sink.add(null));
    } catch (e) {
      logger.shout("Couldn't handle update survey message ${e.toString()}");
    }
  }

  @override
  DeviceSurveyMessage deserializeMessage(String message) =>
      DeviceSurveyMessage.fromJson(jsonDecode(message));

  /// Finds [DeviceSurveyData] by parsing [message] from API
  Future<surveys_api.DeviceSurveyData?> _findDeviceSurveyData(
    String message,
  ) async {
    DeviceSurveyMessage deserializedMessage = deserializeMessage(message);
    surveys_api.DeviceDataApi deviceDataApi =
        await apiFactory.getDeviceDataApi();

    return await deviceDataApi
        .findDeviceDataSurvey(
          deviceId: deserializedMessage.deviceId,
          deviceSurveyId: deserializedMessage.deviceSurveyId,
        )
        .then((value) => value.data);
  }
}
