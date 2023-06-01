import "dart:convert";
import "package:flutter/foundation.dart";
import "package:flutter_dotenv/flutter_dotenv.dart";
import "package:mqtt_client/mqtt_client.dart";
import "package:mqtt_client/mqtt_server_client.dart";
import "package:oss_surveys_api/oss_surveys_api.dart" as surveys_api;
import "package:oss_surveys_customer/database/dao/keys_dao.dart";
import "package:oss_surveys_customer/mqtt/model/status_message.dart";
import "package:typed_data/typed_buffers.dart";
import "../main.dart";

/// MQTT Client
class MqttClient {
  String? _deviceId;
  MqttServerClient? _client;

  Future<String> get _statusTopic async {
    var deviceId = _deviceId;

    if (deviceId == null) {
      logger.warning("Device ID not found, cannot get status topic.");

      return "";
    }

    return "oss/$environment/$deviceId/status";
  }

  bool get isConnected =>
      _getClientConnectionStatus() == MqttConnectionState.connected.name;

  Map<String, Function(String)> listeners = {};

  /// Connects MQTT server using [deviceId] as client id if not already connected.
  Future<void> connect(String deviceId) async {
    _deviceId = deviceId;
    var client = _initializeClient(deviceId);

    var mqttUsername = dotenv.env["MQTT_USERNAME"];
    var mqttPassword = dotenv.env["MQTT_PASSWORD"];
    if (client.connectionStatus!.state == MqttConnectionState.connected) {
      logger.info("MQTT Client already connected");

      return;
    }

    if (await keysDao.getDeviceId() == null) {
      logger.warning("Device ID not found, cannot connect to MQTT.");

      return;
    }

    client.logging(on: false);
    client.onConnected = onConnected;
    client.onDisconnected = onDisconnected;
    client.onUnsubscribed = onUnsubscribed;
    client.onSubscribed = onSubscribed;
    client.onSubscribeFail = onSubscribeFail;

    final connMessage = MqttConnectMessage()
        .keepAliveFor(60)
        .withWillTopic(await _statusTopic)
        .withWillMessage(jsonEncode((await _buildStatusMessage(false))))
        .authenticateAs(mqttUsername, mqttPassword)
        .startClean()
        .withWillQos(MqttQos.atLeastOnce);
    client.connectionMessage = connMessage;
    try {
      await client.connect(
        mqttUsername,
        mqttPassword,
      );
    } catch (e) {
      logger.shout("Exception: $e");
      client.disconnect();
    }

    client.updates?.listen((List<MqttReceivedMessage<MqttMessage>> messages) {
      if (messages.isEmpty) {
        return;
      }

      if (listeners.containsKey(messages[0].topic)) {
        logger.info("Handling message to ${messages[0].topic}...");
        final MqttPublishMessage publishMessage =
            messages[0].payload as MqttPublishMessage;
        String message = MqttPublishPayload.bytesToStringAsString(
            publishMessage.payload.message);
        listeners[messages[0].topic]!(message);
      } else {
        logger.warning("Didn't have listener for topic ${messages[0].topic}");
      }
    });
  }

  /// Handler for successful connections event.
  Future onConnected() async {
    StatusMessage? statusMessage = await _buildStatusMessage(true);

    if (statusMessage == null) {
      logger.info("Device not yet registered, not sending status message!");

      return;
    }

    logger.info("Connected, sending status message...");
    publishMessage(
      await _statusTopic,
      createMessagePayload(statusMessage.toJson().toString()),
    );
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
    _client?.disconnect();
  }

  /// Publishes given MQTT [message] to given [topic].
  ///
  /// If client is not connected, attempts to reconnect.
  void publishMessage(String topic, Uint8Buffer message) async {
    if (_client?.connectionStatus == null) return;
    if (_getClientConnectionStatus() != MqttConnectionState.connected.name) {
      await _reconnect();
    }

    _client?.publishMessage(topic, MqttQos.atLeastOnce, message);
  }

  /// Creates MQTT Message payload from [payload]
  Uint8Buffer createMessagePayload(String payload) {
    Uint8List data = Uint8List.fromList(payload.codeUnits);
    Uint8Buffer buffer = Uint8Buffer();
    buffer.addAll(data);

    return buffer;
  }

  /// Subscribes to given MQTT [topic].
  ///
  /// Quality of Service (QoS) defaults to [MqttQos.atLeastOnce] (1)
  void subscribeToTopic(String topic, {qos = MqttQos.atLeastOnce}) {
    _client?.subscribe(topic, qos);
  }

  /// Subscribes to topics listed in [newListeners] and adds topic:callback pairs to [listeners] for further callback invocation.
  void addListeners(Map<String, Function(String)> newListeners) {
    for (var listener in newListeners.entries) {
      subscribeToTopic(listener.key);
      listeners[listener.key] = listener.value;
    }
  }

  /// Sends [StatusMessage]
  Future sendStatusMessage(bool status) async {
    StatusMessage? statusMessage = await _buildStatusMessage(status);

    if (statusMessage == null) {
      logger.warning("Device not yet registered, cannot send status message.");

      return;
    }

    String statusTopic = await _statusTopic;

    publishMessage(
      statusTopic,
      createMessagePayload(jsonEncode(statusMessage)),
    );
    logger.info("Sent status message to topic: $statusTopic");
  }

  /// Initializes MQTT Client using [deviceId] as client ID.
  ///
  /// Returns initialized MQTT Client.
  MqttServerClient _initializeClient(String deviceId) {
    if (_client != null) {
      return _client!;
    }

    var mqttBasePath = dotenv.env["MQTT_URL"];
    var mqttPort = int.tryParse(dotenv.env["MQTT_PORT"] ?? "");
    _client = MqttServerClient.withPort(mqttBasePath!, deviceId, mqttPort!);

    return _client!;
  }

  /// Builds [StatusMessage]
  Future<StatusMessage?> _buildStatusMessage(
    bool status,
  ) async {
    String? deviceId = _deviceId;

    if (deviceId == null) {
      logger.warning("Device ID not found, cannot send status message.");

      return null;
    }

    return StatusMessage(
      status
          ? surveys_api.DeviceStatus.ONLINE.name
          : surveys_api.DeviceStatus.OFFLINE.name,
      deviceId,
    );
  }

  /// Reconnects MQTT Client.
  ///
  /// In case of failing to connect, retries for 3 times.
  Future<void> _reconnect({retryAttempts = 3}) async {
    logger.info("Attempting to reconnect MQTT Client ($retryAttempts)...");
    try {
      await _client?.connect();
    } catch (e) {
      if (retryAttempts > 0) {
        _reconnect(retryAttempts: retryAttempts - 1);
      } else {
        throw Exception("Couldn't reconnect MQTT Client.");
      }
    }
  }

  /// Gets MQTT Client connection status string.
  String _getClientConnectionStatus() {
    var client = _client;
    if (client == null) {
      return MqttConnectionState.disconnected.name;
    }

    if (client.connectionStatus == null) {
      return MqttConnectionState.faulted.name;
    }

    return client.connectionStatus!.state.name;
  }
}

final mqttClient = MqttClient();
