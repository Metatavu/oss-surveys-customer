import "package:oss_surveys_customer/mqtt/model/abstract_message.dart";

/// MQTT Survey Message Class
class DeviceSurveyMessage implements AbstractMqttMessage {
  DeviceSurveyMessage(this.deviceId, this.deviceSurveyId);

  String deviceId;
  String deviceSurveyId;

  /// Converts JSON to Status Message
  factory DeviceSurveyMessage.fromJson(Map<String, dynamic> json) {
    final deviceId = json["deviceId"] as String;
    final deviceSurveyId = json["surveyId"] as String;

    return DeviceSurveyMessage(deviceId, deviceSurveyId);
  }

  /// Converts Status Message to JSON
  @override
  Map<String, dynamic> toJson() {
    return {"deviceId": deviceId, "deviceSurveyId": deviceSurveyId};
  }
}
