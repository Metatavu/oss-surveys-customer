/// Abstract MQTT Message class
abstract class AbstractMqttMessage {
  AbstractMqttMessage.fromJson(Map<String, dynamic> json);
  Map<String, dynamic> toJson();
}
