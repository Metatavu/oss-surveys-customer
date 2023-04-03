import 'package:oss_surveys_customer/mqtt/mqtt_client.dart';

class MqttClientProvider {
  
  MqttClientProvider._();
  
  static final MqttClient _instance = MqttClient();
  
  static MqttClient getClient() {
    return _instance;
  } 
}