import "package:oss_surveys_customer/mqtt/model/abstract_message.dart";

/// MQTT Survey Message Class
class SurveyMessage implements AbstractMqttMessage {
  SurveyMessage(this.id);

  String id;

  /// Converts JSON to Status Message
  factory SurveyMessage.fromJson(Map<String, dynamic> json) {
    final id = json["id"] as String;

    return SurveyMessage(id);
  }

  /// Converts Status Message to JSON
  @override
  Map<String, dynamic> toJson() {
    return {"id": id};
  }
}
