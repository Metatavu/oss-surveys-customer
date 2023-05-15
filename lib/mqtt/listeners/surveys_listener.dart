import "dart:convert";
import "package:oss_surveys_api/oss_surveys_api.dart" as surveys_api;
import "package:oss_surveys_customer/main.dart";
import "package:oss_surveys_customer/mqtt/listeners/abstract_listener.dart";
import "package:oss_surveys_customer/mqtt/model/device_survey_message.dart";

/// MQTT Surveys Messages listener class
class SurveysListener extends AbstractMqttListener<DeviceSurveyMessage> {
  SurveysListener() {
    setListeners();
  }

  /// TODO: Implement this in later task
  @override
  void handleCreate(String message) async {
    try {
      logger.info("Created new Survey with externalId");
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
