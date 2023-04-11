import "dart:async";
import "dart:io";
import "package:device_info_plus/device_info_plus.dart";
import "package:flutter/material.dart";
import "package:flutter_device_identifier/flutter_device_identifier.dart";
import "package:flutter_dotenv/flutter_dotenv.dart";
import "package:openapi_generator_annotations/openapi_generator_annotations.dart";
import "package:oss_surveys_customer/api/api_factory.dart";
import "package:oss_surveys_customer/database/database.dart";
import "package:oss_surveys_customer/mqtt/listeners/surveys_listener.dart";
import "package:oss_surveys_customer/mqtt/mqtt_client.dart";
import "package:oss_surveys_customer/screens/default_screen.dart";
import "package:oss_surveys_customer/theme/font.dart";
import "package:oss_surveys_customer/theme/theme.dart";
import "package:simple_logger/simple_logger.dart";

final logger = SimpleLogger();
final apiFactory = ApiFactory();

late final String environment;
late bool isDeviceApproved;
late final String deviceSerialNumber;

void main() async {
  _configureLogger();
  await dotenv.load(fileName: ".env");
  environment = dotenv.env["ENVIRONMENT"]!;
  mqttClient.connect().then((_) => _setupMqttListeners());
  deviceSerialNumber = await _getDeviceSerialNumber();
  await loadOfflinedFont();
  isDeviceApproved = await database.isDeviceApproved();
  _setupTimers();
  runApp(const MyApp());
}

/// Configures logger to use [logLevel] and formats log messages to be cleaner than by default.
void _configureLogger({logLevel = Level.INFO}) {
  SimpleLogger().setLevel(logLevel, includeCallerInfo: true);
  SimpleLogger().formatter = ((info) => "[${info.time}] -- ${info.callerFrame ?? "NO CALLER INFO"} - ${info.message}");
}

/// Setups MQTT Listeners
void _setupMqttListeners() {
  SurveysListener();
}

/// Setups timers for background tasks ran on interval.
void _setupTimers() async {
  if (!isDeviceApproved) {
    Timer.periodic(const Duration(seconds: 30), (_) => _pollDeviceApprovalStatus() );
  }
}

/// Polls API for checking if device is approved.
Future<void> _pollDeviceApprovalStatus() async {
  logger.info("Polling device approval status...");
  // TODO: Add API call for polling device approval status.
}

/// Returns the serial number of the device
Future<String> _getDeviceSerialNumber() async {
  if (Platform.isAndroid) {
    await FlutterDeviceIdentifier.requestPermission();
    return await FlutterDeviceIdentifier.serialCode;
  } else if (Platform.isLinux) {
    return await DeviceInfoPlugin().linuxInfo.then((value) => value.data["machineId"]);
  }
  
  throw new Exception("Unsupported operating system!");
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Osuuskauppa Suur-Savo Surveys Consumer",
      theme: getTheme(),
      home: const DefaultScreen(),
    );
  }
}

/// API Client generator config
@Openapi(
    additionalProperties: AdditionalProperties(pubName: "oss_surveys_api"),
    inputSpecFile: "oss-surveys-api-spec/swagger.yaml",
    generatorName: Generator.dio,
    outputDirectory: "oss-surveys-api")
class OssSurveysApi extends OpenapiGeneratorConfig {}