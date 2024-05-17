// Openapi Generator last run: : 2024-05-17T13:30:36.866503
import "dart:async";
import "dart:io";
import "package:device_info_plus/device_info_plus.dart";
import "package:flutter/material.dart";
import "package:flutter_device_identifier/flutter_device_identifier.dart";
import "package:flutter_dotenv/flutter_dotenv.dart";
import "package:openapi_generator_annotations/openapi_generator_annotations.dart";
import "package:oss_surveys_api/oss_surveys_api.dart" as surveys_api;
import "package:oss_surveys_customer/api/api_factory.dart";
import "package:oss_surveys_customer/config/configuration.dart";
import "package:oss_surveys_customer/database/dao/keys_dao.dart";
import "package:oss_surveys_customer/database/dao/surveys_dao.dart";
import "package:oss_surveys_customer/l10n/gen_l10n/app_localizations.dart";
import "package:oss_surveys_customer/mqtt/mqtt_client.dart";
import "package:oss_surveys_customer/screens/default_screen.dart";
import "package:oss_surveys_customer/theme/font.dart";
import "package:oss_surveys_customer/theme/theme.dart";
import "package:oss_surveys_customer/updates/updater.dart";
import "package:oss_surveys_customer/utils/background_service.dart";
import "package:oss_surveys_customer/utils/surveys_controller.dart";
import "package:responsive_framework/responsive_framework.dart";
import "package:sentry_flutter/sentry_flutter.dart";
import "package:simple_logger/simple_logger.dart";
import "database/database.dart";

final apiFactory = ApiFactory();
final StreamController<Survey?> streamController =
    StreamController.broadcast(sync: true);

late final String environment;
late final String deviceSerialNumber;
late final Configuration configuration;
late bool isDeviceApproved;

void main() async {
  _configureLogger();

  SimpleLogger().info("Starting OSS Surveys Customer App...");

  SimpleLogger().info("Loading .env file...");
  await dotenv.load(fileName: ".env");
  SimpleLogger().info("Validating environment variables...");
  configuration = Configuration();

  environment = configuration.getEnvironment();
  SimpleLogger().info("Running in $environment environment");

  String? deviceId = await keysDao.getDeviceId();
  if (deviceId != null) {
    SimpleLogger().info("Connecting to MQTT Broker...");
    await mqttClient.connect(deviceId);
  } else {
    SimpleLogger().info("Device ID not found, cannot connect to MQTT.");
  }

  deviceSerialNumber = await _getDeviceSerialNumber();
  SimpleLogger().info("Device serial number: $deviceSerialNumber");

  WidgetsFlutterBinding.ensureInitialized();

  SimpleLogger().info("Starting Sentry...");
  await _initializeSentryAndRunApp();

  SimpleLogger().info("Loading offlined font...");
  await loadOfflinedFont();

  SimpleLogger().info("Checking if device is approved...");
  isDeviceApproved = await keysDao.isDeviceApproved();

  if (isDeviceApproved) {
    SimpleLogger().info("Device is approved!");
  } else {
    SimpleLogger().info("Device is not approved!");
  }

  if (isDeviceApproved) {
    _getSurveys();
  }

  _setupTimers();
  BackgroundService.start(configuration.getSurveysApiBasePath());
}

/// Configures logger to use [logLevel] and formats log messages to be cleaner than by default.
void _configureLogger({Level logLevel = Level.INFO}) {
  SimpleLogger().setLevel(logLevel, includeCallerInfo: true);
  SimpleLogger().formatter = ((info) =>
      "[${info.time}] -- ${info.callerFrame ?? "NO CALLER INFO"} - ${info.message}");
}

/// Setups timers for background tasks ran on interval.
///
/// Consider investigating https://docs.flutter.dev/packages-and-plugins/background-processes at some point
void _setupTimers() async {
  if (!isDeviceApproved) {
    Timer.periodic(const Duration(seconds: 30),
        (timer) => _pollDeviceApprovalStatus(timer));
  }
  Timer.periodic(
    const Duration(minutes: 1),
    (timer) async {
      if (isDeviceApproved) {
        await _checkActiveSurvey();
      }
    },
  );
}

/// Polls API for checking if device is approved.
Future<void> _pollDeviceApprovalStatus(Timer timer) async {
  SimpleLogger().info("Polling device approval status...");
  surveys_api.DeviceRequestsApi devicesApi =
      await apiFactory.getDeviceRequestsApi();
  try {
    String? deviceId = await keysDao.getDeviceId();
    if (deviceId == null) {
      surveys_api.DeviceRequest? deviceRequest = await devicesApi
          .createDeviceRequest(serialNumber: deviceSerialNumber)
          .then((response) => response.data);

      if (deviceRequest != null) {
        SimpleLogger()
            .info("Created a new Device Request, waiting for approval...");
        keysDao.persistDeviceId(deviceRequest.id!);

        if (!mqttClient.isConnected) {
          SimpleLogger()
              .info("MQTT client is not connected, attempting to connect");
          await mqttClient.connect(deviceRequest.id!);
        }
      }
    } else {
      String? deviceKey = await devicesApi
          .getDeviceKey(requestId: deviceId)
          .then((response) => response.data?.key);

      if (deviceKey != null) {
        SimpleLogger().info("Received device key...");
        await keysDao.persistDeviceKey(deviceKey);
        isDeviceApproved = true;
        SimpleLogger().info("Persisted device key, stopping polling!");
        timer.cancel();
      }
    }
  } catch (exception) {
    SimpleLogger().info("Error: $exception");
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

/// Checks if active survey has changed and pushes it to the stream if it has.
Future<void> _checkActiveSurvey() async {
  await _getSurveys();
  Survey? newActiveSurvey = await surveysDao.findActiveSurvey();
  streamController.sink.add(newActiveSurvey);
}

/// Gets all Surveys assigned to this device
///
/// Retains published surveys (should be only one) and creates a new [Survey] for each of them.
Future<void> _getSurveys() async {
  surveys_api.DeviceDataApi deviceDataApi = await apiFactory.getDeviceDataApi();
  try {
    SimpleLogger().info("Getting surveys...");
    String? deviceId = await keysDao.getDeviceId();

    if (deviceId == null) {
      SimpleLogger().warning("Device ID is null, cannot get surveys!");

      return;
    }

    List<surveys_api.DeviceSurveyData> surveys = [];
    await deviceDataApi
        .listDeviceDataSurveys(deviceId: deviceId)
        .then((deviceDataSurveys) => surveys.addAll(deviceDataSurveys.data!));

    var removedSurveys = (await surveysController.listSurveys()).where(
        (existingSurvey) =>
            !surveys.any((survey) => survey.id == existingSurvey.externalId));

    for (var removedSurvey in removedSurveys) {
      SimpleLogger().info(
        "Removed survey ${removedSurvey.externalId} (${removedSurvey.title}) from the device!",
      );
      await surveysController.deleteSurvey(removedSurvey.externalId);
    }

    for (var survey in surveys) {
      await surveysController.persistSurvey(survey);
    }

    SimpleLogger().info("Finished persisting surveys!");
  } catch (exception, stackTrace) {
    SimpleLogger().shout("Error while getting Surveys: $exception");
    await reportError(exception, stackTrace);
  }
}

/// Initializes Sentry and runs the app
Future<void> _initializeSentryAndRunApp() async {
  await SentryFlutter.init((options) {
    options.dsn = configuration.getSentryDsn();
    options.tracesSampleRate = 1.0;
    options.environment = configuration.getEnvironment();
  }, appRunner: () {
    SimpleLogger().info("Running app...");
    runApp(
      const MyApp(),
    );
  });
  await Sentry.configureScope((scope) async {
    scope.setTag("version", await Updater.getCurrentVersion());
    scope.setTag("serialNumber", deviceSerialNumber);
    scope.setTag("deviceId", await keysDao.getDeviceId() ?? "");
  });
}

/// Sends [exception] to Sentry with optional [stackTrace]
Future<void> reportError(dynamic exception, StackTrace? stackTrace) async {
  await Sentry.captureException(exception, stackTrace: stackTrace);
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      builder: (context, child) => ResponsiveBreakpoints(
        breakpoints: const [
          Breakpoint(start: 0, end: double.infinity, name: "4K"),
        ],
        child: child!,
      ),
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
  inputSpec: InputSpec(path: "oss-surveys-api-spec/swagger.yaml"),
  generatorName: Generator.dio,
  outputDirectory: "oss-surveys-api",
  runSourceGenOnOutput: true,
)
class OssSurveysApi {}