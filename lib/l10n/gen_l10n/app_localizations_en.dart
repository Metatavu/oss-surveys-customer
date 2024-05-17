import 'app_localizations.dart';

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get notYetApproved => 'Device has not yet been approved.';

  @override
  String currentVersion(String currentVersion) {
    return 'Applications current version: $currentVersion';
  }

  @override
  String availableVersion(String availableVersion) {
    return 'Servers version: $availableVersion';
  }

  @override
  String get installVersionButton => 'Install new version';

  @override
  String get loadingSurvey => 'Survey is being loaded...';

  @override
  String mqttClientConnectionStatus(String status) {
    return 'MQTT client connection status: $status';
  }

  @override
  String unsubmittedAnswersCount(int count) {
    return 'Unsubmitted answers: $count';
  }
}
