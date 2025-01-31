import 'dart:io';
import 'dart:async';
import "dart:typed_data";
import "package:mqtt_client/mqtt_client.dart";
import "package:mqtt_client/mqtt_server_client.dart";
import "package:oss_surveys_api/oss_surveys_api.dart" as surveys_api;
import "package:oss_surveys_customer/database/dao/answer_dao.dart";
import "package:oss_surveys_customer/database/dao/keys_dao.dart";
import "package:oss_surveys_customer/mqtt/model/status_message.dart";
import "package:simple_logger/simple_logger.dart";
import "package:typed_data/typed_buffers.dart";
import "../main.dart";
import "../updates/updater.dart";
import "../utils/serialization_utils.dart";
import "listeners/surveys_listener.dart";

/// MQTT Client
class MqttClient {
  String? _deviceId;
  MqttServerClient? _client;

  Future<String> get _statusTopic async {
    var deviceId = _deviceId;

    if (deviceId == null) {
      SimpleLogger().warning("Device ID not found, cannot get status topic.");

      return "";
    }

    return "oss/$environment/$deviceId/status";
  }

  bool get isConnected =>
      _getClientConnectionStatus() == MqttConnectionState.connected.name;

  Map<String, void Function(String)> listeners = {};

  /// Connects MQTT server using [deviceId] as client id if not already connected.
  Future<void> connect(String deviceId) async {
    _deviceId = deviceId;
    var client = await _initializeClient(deviceId);

    var mqttUsername = configuration.getMqttUsername();
    var mqttPassword = configuration.getMqttPassword();
    if (client.connectionStatus!.state == MqttConnectionState.connected) {
      SimpleLogger().info("MQTT Client already connected");

      return;
    }

    if (await keysDao.getDeviceId() == null) {
      SimpleLogger().warning("Device ID not found, cannot connect to MQTT.");

      return;
    }

    client.logging(on: false);
    client.onConnected = onConnected;
    client.onDisconnected = onDisconnected;
    client.onUnsubscribed = onUnsubscribed;
    client.onSubscribed = onSubscribed;
    client.onSubscribeFail = onSubscribeFail;

    final connMessage = MqttConnectMessage()
        .withWillTopic(await _statusTopic)
        .withWillMessage(
          SerializationUtils.serializeObject(
            await _buildStatusMessage(status: false),
            surveys_api.DeviceStatusMessage,
          ),
        )
        .authenticateAs(mqttUsername, mqttPassword)
        .startClean()
        .withWillQos(MqttQos.atLeastOnce);
    client.connectionMessage = connMessage;
    try {
      await client.connect(
        mqttUsername,
        mqttPassword,
      );
    } catch (exception) {
      SimpleLogger().shout("Exception: $exception");
      client.disconnect();
    }

    client.updates?.listen((List<MqttReceivedMessage<MqttMessage>> messages) {
      if (messages.isEmpty) {
        return;
      }

      if (listeners.containsKey(messages[0].topic)) {
        SimpleLogger().info("Handling message to ${messages[0].topic}...");
        final MqttPublishMessage publishMessage =
            messages[0].payload as MqttPublishMessage;
        String message = MqttPublishPayload.bytesToStringAsString(
            publishMessage.payload.message);
        listeners[messages[0].topic]!(message);
      } else {
        SimpleLogger()
            .warning("Didn't have listener for topic ${messages[0].topic}");
      }
    });
  }

  /// Handler for successful connections event.
  Future<void> onConnected() async {
    surveys_api.DeviceStatusMessage? statusMessage =
        await _buildStatusMessage();

    if (statusMessage == null) {
      SimpleLogger()
          .info("Device not yet registered, not sending status message!");

      return;
    }

    SimpleLogger().info("Connected, sending status message...");
    publishMessage(
      await _statusTopic,
      createMessagePayload(
        SerializationUtils.serializeObject(
          statusMessage,
          surveys_api.DeviceStatusMessage,
        ),
      ),
    );
    SimpleLogger().info("Setting up listeners...");
    _setupMqttListeners();
    _initPeriodicStatusMessage();
  }

  /// Handler for disconnection event.
  ///
  /// Attempts to reconnect the client.
  void onDisconnected() {
    SimpleLogger().info("MQTT Client disconnected");
    _reconnect();
  }

  /// Handler for subscribed to topic events.
  void onSubscribed(String topic) {
    SimpleLogger().info("Subscribed to topic: $topic");
  }

  /// Handler for failing to subscribe to topic events.
  void onSubscribeFail(String topic) {
    SimpleLogger().info("Failed to subscribe to: $topic");
  }

  /// Handler for unsubscribing from topic events.
  void onUnsubscribed(String? topic) {
    SimpleLogger().info("Unsubscribed from topic: $topic");
  }

  /// Disconnects MQTT Client
  void disconnect() {
    SimpleLogger().info("Disconnecting MQTT Client...");
    _client?.disconnect();
  }

  /// Publishes given MQTT [message] to given [topic].
  ///
  /// If client is not connected, attempts to reconnect.
  void publishMessage(String topic, Uint8Buffer message) async {
    try {
      if (_client?.connectionStatus == null) return;
      if (_getClientConnectionStatus() != MqttConnectionState.connected.name) {
        await _reconnect();
      }

      _client?.publishMessage(topic, MqttQos.atLeastOnce, message);
    } catch (exception) {
      SimpleLogger().shout(
        "Exception while publishing MQTT message: $exception",
      );
    }
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
  void subscribeToTopic(String topic, {MqttQos qos = MqttQos.atLeastOnce}) {
    _client?.subscribe(topic, qos);
  }

  /// Subscribes to topics listed in [newListeners] and adds topic:callback pairs to [listeners] for further callback invocation.
  void addListeners(Map<String, void Function(String)> newListeners) {
    listeners.removeWhere((key, _) => newListeners.containsKey(key));
    for (var listener in newListeners.entries) {
      subscribeToTopic(listener.key);
      listeners[listener.key] = listener.value;
    }
  }

  /// Sends [StatusMessage]
  Future<void> sendStatusMessage(bool status) async {
    surveys_api.DeviceStatusMessage? statusMessage =
        await _buildStatusMessage();

    if (statusMessage == null) {
      SimpleLogger()
          .warning("Device not yet registered, cannot send status message.");

      return;
    }

    String statusTopic = await _statusTopic;

    publishMessage(
      statusTopic,
      createMessagePayload(
        SerializationUtils.serializeObject(
          statusMessage,
          surveys_api.DeviceStatusMessage,
        ),
      ),
    );
    SimpleLogger().info("Sent status message to topic: $statusTopic");
  }

  /// Initializes MQTT Client using [deviceId] as client ID.
  ///
  /// Returns initialized MQTT Client.
  Future<MqttServerClient> _initializeClient(String deviceId) async {
    var uri = await _getActiveUrl();
    bool secure = uri.scheme.contains("ssl");

    SimpleLogger().info("Initializing MQTT Client...");

    var client = _client;

    if (client != null) {
      if (client.server == uri.host &&
          client.port == uri.port &&
          client.secure == secure) {
        SimpleLogger().info("Reusing existing MQTT client...");
        return client;
      } else {
        SimpleLogger().info("Disconnecting existing MQTT client...");

        if (client.connectionStatus?.state == MqttConnectionState.connected) {
          try {
            client.disconnect();
          } catch (exception) {
            SimpleLogger().shout(
              "Exception while disconnecting MQTT client: $exception",
            );
          }
        }

        _client = null;
      }
    }

    SimpleLogger().info(
        "Connecting to MQTT server at ${uri.host}:${uri.port} with protocol ${secure ? "mqtts" : "mqtt"}... ");

    _client = MqttServerClient.withPort(uri.host, deviceId, uri.port);
    _client?.secure = secure;

    return _client!;
  }

  /// Builds [surveys_api.DeviceStatusMessage]
  Future<surveys_api.DeviceStatusMessage?> _buildStatusMessage(
      {bool status = true}) async {
    final unsentAnswersCount = (await answersDao.listAnswers()).length;
    final versionCode = await Updater.getCurrentVersionCode();
    String? deviceId = _deviceId;

    if (deviceId == null) {
      SimpleLogger()
          .warning("Device ID not found, cannot send status message.");

      return null;
    }

    return surveys_api.DeviceStatusMessage((builder) async {
      builder
        ..deviceId = deviceId
        ..status = mqttClient.isConnected
            ? surveys_api.DeviceStatus.ONLINE
            : surveys_api.DeviceStatus.OFFLINE
        ..versionCode = versionCode
        ..unsentAnswersCount = unsentAnswersCount;
    });
  }

  /// Reconnects MQTT Client.
  ///
  /// Reports Sentry issue every 100th failure.
  Future<void> _reconnect({int failureCount = 0}) async {
    SimpleLogger().info("Attempting to reconnect MQTT Client...");
    try {
      _client = await _initializeClient(_deviceId!);
      await _client?.connect();
    } catch (exception) {
      await _awaitDelay(30);
      await _reconnect(failureCount: failureCount + 1);
    }
  }

  /// Delays for given [delay] seconds.
  Future<void> _awaitDelay(int delay) async {
    return Future.delayed(Duration(seconds: delay));
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

  /// Setups MQTT Listeners
  void _setupMqttListeners() {
    if (mqttClient.isConnected) {
      SurveysListener();
    } else {
      SimpleLogger()
          .warning("MQTT Client not connected, cannot setup listeners!");
    }
  }

  /// Initializes periodic status message.
  void _initPeriodicStatusMessage() {
    Timer.periodic(const Duration(minutes: 1), (timer) {
      if (mqttClient.isConnected) {
        mqttClient.sendStatusMessage(true);
      } else {
        timer.cancel();
      }
    });
  }

  /// Gets active MQTT server URL
  ///
  /// @return Future<Uri> active MQTT server URL
  Future<Uri> _getActiveUrl() async {
    List<String> mqttUrls = configuration.getMqttUrls();
    for (var url in mqttUrls) {
      SimpleLogger().info("Checking MQTT server at $url...");
      var uri = Uri.parse(url);
      if (await _isMqttServerAlive(uri)) {
        SimpleLogger().info("Active MQTT server found at $url");
        return uri;
      } else {
        SimpleLogger().info("MQTT server at $url is not reachable");
      }
    }

    throw Exception("No active MQTT server found!");
  }

  /// Tests if MQTT server is reachable
  ///
  /// @param url MQTT server URL
  /// @return Future<bool> true if the server is reachable; false otherwise
  Future<bool> _isMqttServerAlive(Uri url) async {
    final int port = url.hasPort ? url.port : 1883;
    final String host = url.host;

    try {
      final socket =
          await Socket.connect(host, port, timeout: const Duration(seconds: 5));
      socket.destroy();
      return true;
    } catch (e) {
      SimpleLogger().warning(
          'Failed to connect to MQTT server at $host:$port - ${e.toString()}');
      return false;
    }
  }
}

final mqttClient = MqttClient();
