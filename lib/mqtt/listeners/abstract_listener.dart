import "package:meta/meta.dart";
import "package:oss_surveys_customer/database/dao/keys_dao.dart";
import "package:oss_surveys_customer/mqtt/mqtt_client.dart";
import "package:oss_surveys_customer/main.dart";

/// Abstract MQTT Listener class
abstract class AbstractMqttListener<T> {
  Future<String> get baseTopic async {
    String? deviceId = await keysDao.getDeviceId();
    if (deviceId == null) {
      throw Exception("Device id is null");
    }

    return "oss/$environment/$deviceId/surveys";
  }

  /// Returns a map of topic:callback entries handled by this listener.
  Future<Map<String, void Function(String)>> getListeners() async => {
        "${await baseTopic}/create": handleCreate,
        "${await baseTopic}/update": handleUpdate,
        "${await baseTopic}/delete": handleDelete
      };

  /// Callback function for handling create messages
  void handleCreate(String message);

  /// Callback function for handling update messages
  void handleUpdate(String message);

  /// Callback function for handling delete messages
  void handleDelete(String message);

  /// Sets listeners described here to MQTT Client
  @protected
  Future<void> setListeners() async {
    mqttClient.addListeners(await getListeners());
  }

  /// Deserializes message into [T] object
  T deserializeMessage(String message);
}
