import 'app_localizations.dart';

/// The translations for Finnish (`fi`).
class AppLocalizationsFi extends AppLocalizations {
  AppLocalizationsFi([String locale = 'fi']) : super(locale);

  @override
  String get notYetApproved => 'Laitetta ei ole vielä otettu käyttöön.';

  @override
  String currentVersion(String currentVersion) {
    return 'Laitteen versio: $currentVersion';
  }

  @override
  String availableVersion(String availableVersion) {
    return 'Palvelimella oleva versio: $availableVersion';
  }

  @override
  String get installVersionButton => 'Asenna uusin versio';

  @override
  String get loadingSurvey => 'Ladataan kyselyä...';

  @override
  String mqttClientConnectionStatus(String status) {
    return 'MQTT yhteyden tila: $status';
  }

  @override
  String unsubmittedAnswersCount(int count) {
    return 'Lähettämättömiä vastauksia: $count';
  }
}
