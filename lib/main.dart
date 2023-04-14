import "package:flutter/material.dart";
import "package:flutter_dotenv/flutter_dotenv.dart";
import "package:openapi_generator_annotations/openapi_generator_annotations.dart";
import "package:oss_surveys_customer/api/api_factory.dart";
import "package:oss_surveys_customer/mqtt/listeners/surveys_listener.dart";
import "package:oss_surveys_customer/mqtt/mqtt_client.dart";
import "package:oss_surveys_customer/screens/default_screen.dart";
import "package:oss_surveys_customer/theme/theme.dart";
import "package:simple_logger/simple_logger.dart";

final logger = SimpleLogger();
final apiFactory = ApiFactory();

late final String environment;

void main() async {
  _configureLogger();
  await dotenv.load(fileName: ".env");
  environment = dotenv.env["ENVIRONMENT"]!;
  mqttClient.connect().then((_) => _setupMqttListeners());
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
