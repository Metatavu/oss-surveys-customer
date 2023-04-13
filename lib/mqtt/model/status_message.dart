import 'package:oss_surveys_customer/mqtt/model/abstract_message.dart';

/// MQTT Status Message Class
class StatusMessage implements AbstractMqttMessage {
  
  StatusMessage(this.online);
  
  bool online;
  
  /// Converts JSON to Status Message
  factory StatusMessage.fromJson(Map<String, dynamic> json) {
    final onlin = json["online"] as bool;
    
    return StatusMessage(onlin);
  }
  
  /// Converts Status Message to JSON
  @override
  Map<String, dynamic> toJson() {
    return {
      "online": online
    };
  }
}