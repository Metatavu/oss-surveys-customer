import "dart:convert";
import "package:oss_surveys_api/oss_surveys_api.dart" as surveys_api;
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
      logger.info("Created new Survey with externalId");
    } catch (e) {
      logger.shout("Couldn't handle create survey message ${e.toString()}");
    }
  }

  @override
  void handleUpdate(String message) async {
    try {
      logger.info("Updated Survey with externalId");
    } catch (e) {
      logger.shout("Couldn't handle update survey message ${e.toString()}");
    }
  }

  @override
  void handleDelete(String message) async {
    try {
      logger.info("Deleted Survey with externalId");
    } catch (e) {
      logger.shout("Couldn't handle update survey message ${e.toString()}");
    }
  }

  /// Gets Survey ID from [message]
  DeviceSurveyMessage _getSurveyIdFromMessage(String message) {
    return DeviceSurveyMessage.fromJson(jsonDecode(message));
  }
}
