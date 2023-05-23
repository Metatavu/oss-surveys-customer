import "dart:async";
import "package:flutter/material.dart";
import "package:flutter_svg/svg.dart";
import "package:oss_surveys_customer/database/dao/keys_dao.dart";
import "package:oss_surveys_customer/database/dao/surveys_dao.dart";
import "package:oss_surveys_customer/main.dart";
import "package:flutter_gen/gen_l10n/app_localizations.dart";
import "package:oss_surveys_customer/screens/management_screen.dart";
import "package:oss_surveys_customer/screens/survey_screen.dart";

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
  void _navigateToSurveyScreen() {
    surveysDao.findActiveSurvey().then((survey) {
      if (survey != null) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const SurveyScreen(),
          ),
        );
      }
    });
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      keysDao.isDeviceApproved().then((value) {
        if (!value) {
          Timer.periodic(const Duration(seconds: 10), (timer) async {
            logger.info("Checking if device is approved...");
            if (await keysDao.isDeviceApproved()) {
              logger.info("Device was approved, canceling timer.");
              setState(() {
                _isApprovedDevice = true;
              });
              timer.cancel();
            }
          });
        }
        setState(() {
          _isApprovedDevice = value;
        });
        _navigateToSurveyScreen();
      });
    });
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
      _clicks = 0;
    });
    setState(() {
      _clicks++;
    });
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
            child: Container(
              width: 200,
              height: 200,
              child: TextButton(
                onPressed: _handleManagementButton,
                child: Container(),
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
                      fontSize: 96,
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
