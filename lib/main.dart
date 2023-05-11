import "dart:async";
import "dart:io";
import "package:device_info_plus/device_info_plus.dart";
import "package:drift/drift.dart";
import "package:flutter/material.dart";
import "package:flutter_device_identifier/flutter_device_identifier.dart";
import "package:flutter_dotenv/flutter_dotenv.dart";
import "package:openapi_generator_annotations/openapi_generator_annotations.dart";
import "package:oss_surveys_api/oss_surveys_api.dart" as surveys_api;
import "package:oss_surveys_customer/api/api_factory.dart";
import "package:oss_surveys_customer/database/dao/keys_dao.dart";
import "package:oss_surveys_customer/database/dao/surveys_dao.dart";
import "package:oss_surveys_customer/database/database.dart";
import "package:oss_surveys_customer/mqtt/listeners/surveys_listener.dart";
import "package:oss_surveys_customer/mqtt/mqtt_client.dart";
import "package:oss_surveys_customer/screens/default_screen.dart";
import "package:oss_surveys_customer/theme/font.dart";
import "package:oss_surveys_customer/theme/theme.dart";
import "package:oss_surveys_customer/utils/pages_controller.dart";
import "package:simple_logger/simple_logger.dart";
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

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
  isDeviceApproved = await keysDao.isDeviceApproved();

  if (isDeviceApproved) {
    _getSurveys();
  }

  _setupTimers();
  runApp(const MyApp());
}

/// Configures logger to use [logLevel] and formats log messages to be cleaner than by default.
void _configureLogger({logLevel = Level.INFO}) {
  SimpleLogger().setLevel(logLevel, includeCallerInfo: true);
  SimpleLogger().formatter = ((info) =>
      "[${info.time}] -- ${info.callerFrame ?? "NO CALLER INFO"} - ${info.message}");
}

/// Setups MQTT Listeners
void _setupMqttListeners() {
  SurveysListener();
}

/// Setups timers for background tasks ran on interval.
void _setupTimers() async {
  if (!isDeviceApproved) {
    Timer.periodic(const Duration(seconds: 30),
        (timer) => _pollDeviceApprovalStatus(timer));
  }
}

/// Polls API for checking if device is approved.
Future<void> _pollDeviceApprovalStatus(Timer timer) async {
  logger.info("Polling device approval status...");
  surveys_api.DeviceRequestsApi devicesApi =
      await apiFactory.getDeviceRequestsApi();
  try {
    String? deviceId = await keysDao.getDeviceId();
    if (deviceId == null) {
      surveys_api.DeviceRequest? deviceRequest = await devicesApi
          .createDeviceRequest(serialNumber: deviceSerialNumber)
          .then((response) => response.data);

      if (deviceRequest != null) {
        logger.info("Created a new Device Request, waiting for approval...");
        keysDao.persistDeviceId(deviceRequest.id!);
      }
    } else {
      String? deviceKey = await devicesApi
          .getDeviceKey(requestId: deviceId)
          .then((response) => response.data?.key);

      if (deviceKey != null) {
        logger.info("Received device key...");
        await keysDao.persistDeviceKey(deviceKey);
        isDeviceApproved = true;
        logger.info("Persisted device key, stopping polling!");
        timer.cancel();
      }
    }
  } catch (e) {
    logger.info("Error: $e");
  }
}

/// Returns the serial number of the device
Future<String> _getDeviceSerialNumber() async {
  if (Platform.isAndroid) {
    await FlutterDeviceIdentifier.requestPermission();
    return await FlutterDeviceIdentifier.serialCode;
  } else if (Platform.isLinux) {
    return await DeviceInfoPlugin()
        .linuxInfo
        .then((value) => value.data["machineId"]);
  }

  throw Exception("Unsupported operating system!");
}

/// Gets all Surveys assigned to this device
///
/// Retains published surveys (should be only one) and creates a new [Survey] for each of them.
Future<void> _getSurveys() async {
  surveys_api.DeviceDataApi deviceDataApi = await apiFactory.getDeviceDataApi();
  try {
    String? deviceId = await keysDao.getDeviceId();

    if (deviceId == null) {
      logger.warning("Device ID is null, cannot get surveys!");
      return;
    }
    List<surveys_api.DeviceSurveyData> surveys = [];
    deviceDataApi
        .listDeviceDataSurveys(deviceId: deviceId)
        .then((deviceDataSurveys) => surveys.addAll(deviceDataSurveys.data!));

    surveys.retainWhere(
        (survey) => survey.status == surveys_api.DeviceSurveyStatus.PUBLISHED);

    logger.info("Received ${surveys.length} surveys!");

    for (var survey in surveys) {
      Survey persistedSurvey =
          await surveysDao.createSurvey(SurveysCompanion.insert(
        externalId: survey.id!,
        title: "",
        publishStart: Value(survey.publishStartTime),
        publishEnd: Value(survey.publishEndTime),
        timeout: 0,
      ));
      if (survey.pages != null) {
        for (var page in survey.pages!) {
          pagesController.persistPage(page, persistedSurvey.id);
        }
      }
    }

    logger.info("Finished persisting surveys!");
  } catch (e) {
    logger.shout("Error while getting Surveys: $e");
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: getTheme(),
      home: const DefaultScreen(),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
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
