import "package:flutter/material.dart";
import "package:flutter_dotenv/flutter_dotenv.dart";
import "package:openapi_generator_annotations/openapi_generator_annotations.dart";
import "package:oss_surveys_customer/api/api_factory.dart";
import "package:oss_surveys_customer/mqtt/mqtt_client.dart";
import "package:simple_logger/simple_logger.dart";

final logger = SimpleLogger();
final apiFactory = ApiFactory();

void main() async {
  _configureLogger();
  await dotenv.load(fileName: ".env");
  mqttClient.connect();
  runApp(const MyApp());
}

/// Configures logger to use [logLevel] and formats log messages to be cleaner than by default.
void _configureLogger({logLevel = Level.INFO}) {
  SimpleLogger().setLevel(logLevel);
  SimpleLogger().formatter = ((info) => "[${info.time}] -- ${info.callerFrame ?? "NO CALLER INFO"} - ${info.message}");
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Flutter Demo",
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: "Flutter Demo Home Page"),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {

  @override
  Widget build(BuildContext context) {
    
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
        ),
      ),
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