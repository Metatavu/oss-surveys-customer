import "package:meta/meta.dart";
import "package:oss_surveys_customer/mqtt/mqtt_client.dart";

/// Abstract MQTT Listener class
abstract class AbstractMqttListener {
  abstract String baseTopic;

  /// Returns a map of topic:callback entries handled by this listener.
  Map<String, Function(String)> getListeners() => {
        "$baseTopic/create": handleCreate,
        "$baseTopic/update": handleUpdate,
        "$baseTopic/delete": handleDelete
      };

  /// Callback function for handling create messages
  void handleCreate(String message);

  /// Callback function for handling update messages
  void handleUpdate(String message);

  /// Callback function for handling delete messages
  void handleDelete(String message);

  /// Sets listeners described here to MQTT Client
  @protected
  void setListeners() {
    mqttClient.addListeners(getListeners());
  }
}
