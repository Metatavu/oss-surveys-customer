import 'package:meta/meta.dart';
import 'package:oss_surveys_customer/mqtt/mqtt_client.dart';

/// Abstract MQTT Listener class
abstract class AbstractMqttListener {
  
  Map<String, Function(String)> getListeners();
  
  void handleMessage(String message);

  @protected
  void setListeners() {
      mqttClient.addListeners(getListeners());
  }  
}