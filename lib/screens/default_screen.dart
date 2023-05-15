import "dart:async";
import "package:flutter/material.dart";
import "package:flutter_svg/svg.dart";
import "package:oss_surveys_customer/database/dao/keys_dao.dart";
import "package:oss_surveys_customer/database/dao/surveys_dao.dart";
import "package:oss_surveys_customer/main.dart";
import "package:flutter_gen/gen_l10n/app_localizations.dart";
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

  /// Navigates to [SurveyScreen] if device is approved and it has active survey.
  ///
  /// Cancels pending [timer]
  void _navigateToSurveyScreen(Timer timer) {
    surveysDao.findActiveSurvey().then((survey) {
      if (survey != null) {
        timer.cancel();
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SurveyScreen(survey: survey),
          ),
        );
      } else {
        logger.info("No active survey found.");
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
        Timer.periodic(const Duration(seconds: 10), (timer) async {
          _navigateToSurveyScreen(timer);
        });
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).primaryColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (!_isApprovedDevice)
              Text(
                AppLocalizations.of(context)!.notYetApproved,
                style: const TextStyle(
                  fontFamily: "S-Bonus-Regular",
                  color: Color(0xffffffff),
                  fontSize: 30,
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
    );
  }
}
