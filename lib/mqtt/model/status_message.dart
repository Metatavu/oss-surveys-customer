import "package:oss_surveys_customer/mqtt/model/abstract_message.dart";

/// MQTT Status Message Class
class StatusMessage implements AbstractMqttMessage {
  StatusMessage(this.status, this.deviceId);

  String status;
  String deviceId;

  /// Converts JSON to Status Message
  factory StatusMessage.fromJson(Map<String, dynamic> json) {
    final status = json["status"] as String;
    final deviceId = json["deviceId"] as String;

    return StatusMessage(status, deviceId);
  }

  /// Converts Status Message to JSON
  @override
  Map<String, dynamic> toJson() {
    return {
      "status": status,
      "deviceId": deviceId,
    };
  }
}
