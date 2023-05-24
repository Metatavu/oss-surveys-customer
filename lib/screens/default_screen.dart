import "dart:async";
import "package:flutter/material.dart";
import "package:flutter_svg/svg.dart";
import "package:oss_surveys_customer/database/dao/keys_dao.dart";
import "package:oss_surveys_customer/database/dao/surveys_dao.dart";
import "package:oss_surveys_customer/main.dart";
import "package:flutter_gen/gen_l10n/app_localizations.dart";
import "package:oss_surveys_customer/screens/management_screen.dart";
import "package:oss_surveys_customer/screens/survey_screen.dart";
import "../database/database.dart";

/// Default Screen
class DefaultScreen extends StatefulWidget {
  const DefaultScreen({super.key});

  @override
  State<DefaultScreen> createState() => _DefaultScreenState();
}

/// Default Screen state
class _DefaultScreenState extends State<DefaultScreen> {
  bool _isApprovedDevice = false;
  int _clicks = 0;

  /// Navigates to [SurveyScreen] if device is approved and it has active survey.
  Future _navigateToSurveyScreen(BuildContext context, Survey survey) async {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => SurveyScreen(survey: survey),
      ),
    );
  }

  /// Polls database with 10 second interval to check if device is approved.
  Future _checkDeviceApproval() async {
    bool isApproved = await keysDao.isDeviceApproved();
    if (!isApproved) {
      Timer.periodic(const Duration(seconds: 10), (timer) async {
        logger.info("Checking if device is approved...");
        if (await keysDao.isDeviceApproved()) {
          logger.info("Device was approved, canceling timer.");
          timer.cancel();
          setState(() => _isApprovedDevice = true);
        }
      });
    } else {
      setState(() => _isApprovedDevice = true);
    }
  }

  /// Polls database with 10 second interval to check if device has active survey.
  Future _pollActiveSurvey() async {
    Timer.periodic(const Duration(seconds: 10), (timer) async {
      Survey? foundSurvey = await surveysDao.findActiveSurvey();
      if (foundSurvey != null && context.mounted) {
        timer.cancel();
        await _navigateToSurveyScreen(context, foundSurvey);
      } else {
        logger.info("No active survey found.");
      }
    });
  }

  /// Sets up timers for checking if device is approved and if there is active survey.
  Future _setupTimers() async {
    await _checkDeviceApproval();
    await _pollActiveSurvey();
  }

  @override
  void initState() {
    super.initState();
    _setupTimers();
  }

  void _handleManagementButton() {
    if (_clicks >= 10) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const ManagementScreen(),
        ),
      );
    }

    Timer(const Duration(seconds: 5), () {
      setState(() => _clicks = 0);
    });
    setState(() => _clicks++);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).primaryColor,
      body: Stack(
        children: [
          Positioned(
            left: 0,
            top: 0,
            child: SizedBox(
              width: 200,
              height: 200,
              child: TextButton(
                onPressed: _handleManagementButton,
                style: TextButton.styleFrom(
                  splashFactory: NoSplash.splashFactory,
                ),
                child: const SizedBox(),
              ),
            ),
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (!_isApprovedDevice)
                  Text(
                    AppLocalizations.of(context)!.notYetApproved,
                    style: const TextStyle(
                      fontFamily: "S-Bonus-Regular",
                      color: Color(0xffffffff),
                      fontSize: 50,
                    ),
                  ),
                SvgPicture.asset(
                  "assets/logo.svg",
                  width: MediaQuery.of(context).size.width * 0.7,
                  height: MediaQuery.of(context).size.height * 0.7,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
