import 'dart:convert';
import 'package:oss_surveys_customer/mqtt/listeners/abstract_listener.dart';
import 'package:oss_surveys_customer/mqtt/model/status_message.dart';

/// MQTT Status Messages listener class
class StatusListener extends AbstractMqttListener {

  @override
  Map<String, Function(String)> getListeners() => {
    "oss/status":handleMessage
  };
  
  @override
  void handleMessage(String message) {
    StatusMessage status = StatusMessage.fromJson(jsonDecode(message));
    print(status.status);
  }
  
  StatusListener() {
    setListeners();
  }
}