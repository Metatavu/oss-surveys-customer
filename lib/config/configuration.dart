// ignore_for_file: constant_identifier_names

import "package:flutter_dotenv/flutter_dotenv.dart";

/// Application configuration
///
/// Validates that all environment variables are in place and provides API for accessing them
class Configuration {
  static const String SURVEYS_API_BASE_PATH = "SURVEYS_API_BASE_PATH";
  static const String MQTT_URL = "MQTT_URL";
  static const String MQTT_PORT = "MQTT_PORT";
  static const String MQTT_USERNAME = "MQTT_USERNAME";
  static const String MQTT_PASSWORD = "MQTT_PASSWORD";
  static const String MQTT_CLIENT_ID = "MQTT_CLIENT_ID";
  static const String ENVIRONMENT = "ENVIRONMENT";
  static const String FONT_URL = "FONT_URL";
  static const String PLATFORM = "PLATFORM";
  static const String APP_UPDATES_BASE_URL = "APP_UPDATES_BASE_URL";
  static const String IMAGE_BASE_URL = "IMAGE_BASE_URL";
  static const String SENTRY_DSN = "SENTRY_DSN";

  static final Configuration _instance = Configuration._();
  factory Configuration() => _instance;

  /// Private constructor
  ///
  /// Validates that all environment variables are in place.
  /// Append new variables to [keys] list.
  Configuration._() {
    Map<String, String> env = dotenv.env;
    List<String> missingKeys = [];
    List<String> keys = [
      SURVEYS_API_BASE_PATH,
      MQTT_URL,
      MQTT_PORT,
      MQTT_USERNAME,
      MQTT_PASSWORD,
      MQTT_CLIENT_ID,
      ENVIRONMENT,
      FONT_URL,
      PLATFORM,
      APP_UPDATES_BASE_URL,
      IMAGE_BASE_URL,
      SENTRY_DSN
    ];

    for (final key in keys) {
      if (!env.containsKey(key)) {
        missingKeys.add(key);
      }
    }

    if (missingKeys.isNotEmpty) {
      throw Exception(
          "Missing environment variables: ${missingKeys.join(", ")}");
    }
  }

  /// Returns value of [key] from environment variables
  String get(String key) => dotenv.env[key]!;

  String getSurveysApiBasePath() => dotenv.env[SURVEYS_API_BASE_PATH]!;
  String getMqttUrl() => dotenv.env[MQTT_URL]!;
  String getMqttPort() => dotenv.env[MQTT_PORT]!;
  String getMqttUsername() => dotenv.env[MQTT_USERNAME]!;
  String getMqttPassword() => dotenv.env[MQTT_PASSWORD]!;
  String getMqttClientId() => dotenv.env[MQTT_CLIENT_ID]!;
  String getEnvironment() => dotenv.env[ENVIRONMENT]!;
  String getFontUrl() => dotenv.env[FONT_URL]!;
  String getPlatform() => dotenv.env[PLATFORM]!;
  String getAppUpdatesBaseUrl() => dotenv.env[APP_UPDATES_BASE_URL]!;
  String getImageBaseUrl() => dotenv.env[IMAGE_BASE_URL]!;
  String getSentryDsn() => dotenv.env[SENTRY_DSN]!;
}
