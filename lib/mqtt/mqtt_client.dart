import "package:flutter/foundation.dart";
import 'package:flutter_dotenv/flutter_dotenv.dart';
import "package:mqtt_client/mqtt_client.dart";
import "package:mqtt_client/mqtt_server_client.dart";
import "package:oss_surveys_customer/mqtt/model/status_message.dart";
import "package:simple_logger/simple_logger.dart";
import "package:typed_data/typed_buffers.dart";

/// MQTT Client
class MqttClient {
  
  late final MqttServerClient _client;
  final logger = SimpleLogger();
  final statusTopic = "oss/status";
  
  /// Public constructor.
  /// 
  /// Initializes [MqttServerClient]
  MqttClient() {
    var mqttBasePath = dotenv.env["MQTT_URL"];
    var mqttClientId = dotenv.env["MQTT_PORT"];
    var mqttPort = int.tryParse(dotenv.env["MQTT_PORT"] ?? "");
    _client = MqttServerClient.withPort(mqttBasePath!, mqttClientId!, mqttPort!);
  }
  
  /// Connects MQTT Client if not already connected.
  Future<void> connect() async {
    if (_client.connectionStatus!.state == MqttConnectionState.connected) {
      logger.info("MQTT Client already connected");
      return;
    }
    
    _client.logging(on: true);
    _client.onConnected = onConnected;
    _client.onDisconnected = onDisconnected;
    _client.onUnsubscribed = onUnsubscribed;
    _client.onSubscribed = onSubscribed;
    _client.onSubscribeFail = onSubscribeFail;

    final connMessage = MqttConnectMessage()
        .keepAliveFor(60)
        .withWillTopic(statusTopic)
        .withWillMessage(StatusMessage(false).toJson().toString())
        .startClean()
        .withWillQos(MqttQos.atLeastOnce);
    _client.connectionMessage = connMessage;
    try {
      await _client.connect();
    } catch (e) {
      logger.shout("Exception: $e");
      _client.disconnect();
    }

    _client.updates?.listen((List<MqttReceivedMessage<MqttMessage>> c) {
      final MqttPublishMessage message = c[0].payload as MqttPublishMessage;
      final payload =
      MqttPublishPayload.bytesToStringAsString(message.payload.message);

      logger.info("Received message:$payload from topic: ${c[0].topic}>");
    });
  }
  
  /// Handler for successful connections event.
  void onConnected() {
    logger.info("Connected, sending status message...");
    publishMessage(statusTopic, createMessagePayload(StatusMessage(true).toJson().toString()));
  }

  /// Handler for disconnection event.
  void onDisconnected() {
    logger.info("Disconnected");
  }

  /// Handler for subscribed to topic events.
  void onSubscribed(String topic) {
    logger.info("Subscribed to topic: $topic");
  }

  /// Handler for failing to subscribe to topic events.
  void onSubscribeFail(String topic) {
    logger.info("Failed to subscribe to: $topic");
  }

  /// Handler for unsubscribing from topic events.
  void onUnsubscribed(String? topic) {
    logger.info("Unsubscribed from topic: $topic");
  }
  
  /// Disconnects MQTT Client
  void disconnect() {
    logger.info("Disconnecting...");
    _client.disconnect();
  }
  
  /// Reconnects MQTT Client.
  /// 
  /// In case of failing to connect, retries for 3 times.
  Future<void> _reconnect({ retryAttempts = 3 }) async {
    logger.info("Attempting to reconnect MQTT Client ($retryAttempts)...");
    try {
      await _client.connect();
    } catch (e) {
      if (retryAttempts > 0) {
        _reconnect(retryAttempts: retryAttempts - 1);
      } else {
        throw Exception("Couldn't reconnect MQTT Client.");
      }
    }
  }
  
  /// Gets MQTT Client connection status string.
  String getClientConnectionStatus() {
    if (_client.connectionStatus == null) {
      return MqttConnectionState.faulted.name;
    }
    
    return _client.connectionStatus!.state.name;
  }
  
  /// Publishes given MQTT [message] to given [topic].
  /// 
  /// If client is not connected, attempts to reconnect.
  void publishMessage(String topic, Uint8Buffer message) async {
    if (_client.connectionStatus == null) return;
    if (getClientConnectionStatus() != MqttConnectionState.connected.name) {
      await _reconnect();
    }
    
    _client.publishMessage(topic, MqttQos.atLeastOnce, message);
  }
  
  /// Creates MQTT Message payload from [payload]
  Uint8Buffer createMessagePayload(String payload) {
    Uint8List data = Uint8List.fromList(payload.codeUnits);
    Uint8Buffer buffer = Uint8Buffer();
    buffer.addAll(data);
    
    return buffer;
  }
}

final mqttClient = MqttClient();