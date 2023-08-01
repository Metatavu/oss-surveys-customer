import "dart:async";
import "package:flutter/material.dart";
import "package:oss_surveys_customer/main.dart";
import "package:oss_surveys_customer/mqtt/mqtt_client.dart";
import "dart:core";
import "package:oss_surveys_customer/updates/updater.dart";
import "package:flutter_gen/gen_l10n/app_localizations.dart";

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
  bool _error = false;
  bool _loading = true;
  bool _isMqttConnected = false;

  /// On click handler for button
  Future _handleUpdate() async {
    setState(() {
      _loading = true;
    });
    await Updater.updateVersion(configuration.getPlatform());
    setState(() {
      _loading = false;
    });
  }

  /// Checks applications current and available version numbers
  Future _checkVersions() async {
    String currentVersion = await Updater.getCurrentVersion();
    String? serverVersion = (await Updater.getServerVersion(
      configuration.getPlatform(),
    ));

    setState(() {
      _currentVersion = currentVersion;
      _serverVersion = serverVersion ?? "Verkkovirhe";
      _loading = false;
      _error = serverVersion == null;
    });
  }

  @override
  void initState() {
    super.initState();
    _checkVersions();
    setState(() => _isMqttConnected = mqttClient.isConnected);
    Timer.periodic(
      const Duration(seconds: 1),
      (_) => setState(() => _isMqttConnected = mqttClient.isConnected),
    );
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
                      onPressed: _error ? null : _handleUpdate,
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
                ],
              ),
      ),
    );
  }
}
