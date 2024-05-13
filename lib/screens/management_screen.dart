import "dart:async";
import "package:flutter/material.dart";
import "package:oss_surveys_customer/database/dao/answer_dao.dart";
import "package:oss_surveys_customer/database/database.dart";
import "package:oss_surveys_customer/l10n/gen_l10n/app_localizations.dart";
import "package:oss_surveys_customer/main.dart";
import "package:oss_surveys_customer/mqtt/mqtt_client.dart";
import "dart:core";
import "package:oss_surveys_customer/updates/updater.dart";

/// Management Screen
///
/// This screen is used to manage application updates.
class ManagementScreen extends StatefulWidget {
  const ManagementScreen({super.key});

  @override
  State<ManagementScreen> createState() => _ManagementScreenState();
}

/// Management Screen state
class _ManagementScreenState extends State<ManagementScreen> {
  String _currentVersion = "";
  String _serverVersion = "";
  bool _serverVersionResolvingError = false;
  bool _loading = true;
  bool _isMqttConnected = false;
  int _unsubmittedAnswersCount = 0;
  Timer? _mqttTimer;

  /// On click handler for button
  Future<void> _handleUpdate() async {
    setState(() {
      _loading = true;
    });
    await Updater.updateVersion(configuration.getPlatform());
    setState(() {
      _loading = false;
    });
  }

  /// Checks applications current and available version numbers
  Future<void> _checkVersions() async {
    String currentVersion = await Updater.getCurrentVersion();
    String? serverVersion = (await Updater.getServerVersion(
      configuration.getPlatform(),
    ));

    setState(() {
      _currentVersion = currentVersion;
      _serverVersion = serverVersion ?? "Verkkovirhe";
      _loading = false;
      _serverVersionResolvingError = serverVersion == null;
    });
  }

  /// Counts unsubmitted answers from local database
  Future<void> _countUnsubmittedAnswers() async {
    List<Answer> unsubmittedAnswers = await answersDao.listAnswers();
    setState(() {
      _unsubmittedAnswersCount = unsubmittedAnswers.length;
    });
  }

  @override
  void initState() {
    super.initState();
    _checkVersions();
    _countUnsubmittedAnswers();
    setState(() => _isMqttConnected = mqttClient.isConnected);
    _mqttTimer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => setState(() => _isMqttConnected = mqttClient.isConnected),
    );
  }

  @override
  void dispose() {
    _mqttTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButtonLocation: FloatingActionButtonLocation.endTop,
      floatingActionButton: SizedBox(
        width: 200,
        height: 200,
        child: FittedBox(
          child: FloatingActionButton.large(
            child: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
        ),
      ),
      body: Center(
        child: _loading
            ? CircularProgressIndicator(color: Theme.of(context).primaryColor)
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    AppLocalizations.of(context)!
                        .currentVersion(_currentVersion),
                    style: const TextStyle(fontSize: 50),
                  ),
                  Text(
                    AppLocalizations.of(context)!
                        .availableVersion(_serverVersion),
                    style: const TextStyle(fontSize: 50),
                  ),
                  SizedBox(
                    child: ElevatedButton(
                      style: ButtonStyle(
                        padding: MaterialStateProperty.all(
                          EdgeInsetsGeometry.lerp(
                            const EdgeInsets.all(20),
                            const EdgeInsets.all(30),
                            0.5,
                          ),
                        ),
                      ),
                      onPressed:
                          _serverVersionResolvingError ? null : _handleUpdate,
                      child: Text(
                        AppLocalizations.of(context)!.installVersionButton,
                        style: const TextStyle(fontSize: 50),
                      ),
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.only(top: 10),
                    child: Text(
                      AppLocalizations.of(context)!.mqttClientConnectionStatus(
                        _isMqttConnected ? "online" : "offline",
                      ),
                      style: const TextStyle(fontSize: 50),
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.only(top: 10),
                    child: Text(
                      AppLocalizations.of(context)!.unsubmittedAnswersCount(
                        _unsubmittedAnswersCount,
                      ),
                      style: const TextStyle(fontSize: 50),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
