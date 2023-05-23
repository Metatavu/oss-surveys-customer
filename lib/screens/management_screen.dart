import "package:flutter/material.dart";
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
  bool _loading = true;
  bool _updateAvailable = false;

  /// On click handler for button
  Future _handleUpdate() async {
    await Updater.updateVersion();
  }

  /// Checks applications current and available version numbers
  Future _checkVersions() async {
    bool updateAvailable = false;
    String currentVersion = await Updater.getCurrentVersion();
    String serverVersion = (await Updater.checkVersion())
        .elements
        .firstWhere((element) => element.filters.first.value == "arm64-v8a")
        .versionName;

    int? currentVersionNumber = int.tryParse(
        currentVersion.split(".").map((n) => int.tryParse(n)).join());
    int? serverVersionNumber = int.tryParse(
        serverVersion.split(".").map((n) => int.tryParse(n)).join());

    if (currentVersionNumber != null && serverVersionNumber != null) {
      updateAvailable = serverVersionNumber > currentVersionNumber;
    }

    setState(() {
      _currentVersion = currentVersion;
      _serverVersion = serverVersion;
      _updateAvailable = updateAvailable;
      _loading = false;
    });
  }

  @override
  void initState() {
    super.initState();
    _checkVersions();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: BackButton(
        onPressed: () => Navigator.pop(context),
      ),
      body: Center(
        child: _loading
            ? CircularProgressIndicator(
                color: Theme.of(context).primaryColor,
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    AppLocalizations.of(context)!
                        .currentVersion(_currentVersion),
                  ),
                  Text(
                    AppLocalizations.of(context)!
                        .availableVersion(_serverVersion),
                  ),
                  ElevatedButton(
                    onPressed: _updateAvailable ? _handleUpdate : null,
                    child: Text(
                        AppLocalizations.of(context)!.installVersionButton),
                  ),
                ],
              ),
      ),
    );
  }
}
