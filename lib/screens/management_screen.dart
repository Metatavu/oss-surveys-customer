import "package:flutter/material.dart";
import "package:flutter_dotenv/flutter_dotenv.dart";
import "dart:core";
import "package:oss_surveys_customer/updates/updater.dart";
import "package:flutter_gen/gen_l10n/app_localizations.dart";
import "package:oss_surveys_customer/utils/extensions.dart";

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

  /// On click handler for button
  Future _handleUpdate() async {
    setState(() {
      _loading = true;
    });
    await Updater.updateVersion(dotenv.env["PLATFORM"]!);
    setState(() {
      _loading = false;
    });
  }

  /// Checks applications current and available version numbers
  Future _checkVersions() async {
    String currentVersion = await Updater.getCurrentVersion();
    String serverVersion = (await Updater.checkVersion())
        .elements
        .firstWhere(
            (element) => element.filters.first.value == dotenv.env["PLATFORM"]!)
        .versionName;

    setState(() {
      _currentVersion = currentVersion;
      _serverVersion = serverVersion;
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
            ? CircularProgressIndicator(
                color: Theme.of(context).primaryColor,
              )
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
                      onPressed: _handleUpdate,
                      child: Text(
                        AppLocalizations.of(context)!.installVersionButton,
                        style: const TextStyle(fontSize: 50),
                      ),
                    ),
                  )
                ],
              ),
      ),
    );
  }
}
