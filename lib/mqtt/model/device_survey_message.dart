import "package:oss_surveys_api/oss_surveys_api.dart";
import "package:oss_surveys_customer/mqtt/model/abstract_message.dart";

/// MQTT Survey Message Class
class DeviceSurveyMessage implements AbstractMqttMessage {
  DeviceSurveyMessage(this.deviceId, this.deviceSurveyId, this.action);

  String deviceId;
  String deviceSurveyId;
  DeviceSurveysMessageAction action;

  /// Converts JSON to Status Message
  factory DeviceSurveyMessage.fromJson(Map<String, dynamic> json) {
    final deviceId = json["deviceId"] as String;
    final deviceSurveyId = json["deviceSurveyId"] as String;
    final action = DeviceSurveysMessageAction.values
        .firstWhere((e) => e.name == json["action"]);

    return DeviceSurveyMessage(deviceId, deviceSurveyId, action);
  }

  /// Converts Status Message to JSON
  @override
  Map<String, dynamic> toJson() {
    return {
      "deviceId": deviceId,
      "deviceSurveyId": deviceSurveyId,
      "action": action.name,
    };
  }
}
