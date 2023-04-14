import "package:oss_surveys_customer/mqtt/model/abstract_message.dart";

/// MQTT Status Message Class
class StatusMessage implements AbstractMqttMessage {
  StatusMessage(this.status);

  bool status;

  /// Converts JSON to Status Message
  factory StatusMessage.fromJson(Map<String, dynamic> json) {
    final status = json["status"] as bool;

    return StatusMessage(status);
  }

  /// Converts Status Message to JSON
  Map<String, dynamic> toJson() {
    return {"status": status};
  }
}
