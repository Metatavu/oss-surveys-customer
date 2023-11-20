import "dart:async";
import "package:flutter/material.dart";
import "package:flutter_svg/svg.dart";
import "package:oss_surveys_customer/database/dao/keys_dao.dart";
import "package:oss_surveys_customer/database/dao/surveys_dao.dart";
import "package:flutter_gen/gen_l10n/app_localizations.dart";
import "package:oss_surveys_customer/screens/management_screen.dart";
import "package:oss_surveys_customer/screens/survey_screen.dart";
import "package:simple_logger/simple_logger.dart";
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
  Timer? _deviceApprovalTimer;
  late Timer _surveyNavigationTimer;

  /// Navigates to [SurveyScreen] if device is approved and it has active survey.
  Future<void> _navigateToSurveyScreen(
    BuildContext context,
    Survey survey,
  ) async {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute<SurveyScreen>(
        builder: (context) => SurveyScreen(survey: survey),
      ),
    ).then((_) => _setupTimers());
  }

  /// Polls database with 10 second interval to check if device is approved.
  Future<void> _checkDeviceApproval() async {
    bool isApproved = await keysDao.isDeviceApproved();
    if (!isApproved) {
      _deviceApprovalTimer =
          Timer.periodic(const Duration(seconds: 10), (timer) async {
        SimpleLogger().info("Checking if device is approved...");
        if (await keysDao.isDeviceApproved()) {
          SimpleLogger().info("Device was approved, canceling timer.");
          timer.cancel();
          setState(() => _isApprovedDevice = true);
        }
      });
    } else {
      setState(() => _isApprovedDevice = true);
    }
  }

  /// Polls database with 10 second interval to check if device has active survey.
  Future<void> _pollActiveSurvey() async {
    _surveyNavigationTimer =
        Timer.periodic(const Duration(seconds: 10), (timer) async {
      List<Survey> surveys = await surveysDao.listSurveys();
      if (surveys.isNotEmpty) {
        SimpleLogger().info("Found Surveys!");
        for (var survey in surveys) {
          SimpleLogger().info("Survey: $survey");
        }
      } else {
        SimpleLogger().info("No surveys found.");
      }
      Survey? foundSurvey = await surveysDao.findActiveSurvey();
      if (foundSurvey != null && context.mounted) {
        timer.cancel();
        SimpleLogger().info("Active survey ${foundSurvey.title} found!");
        await _navigateToSurveyScreen(context, foundSurvey);
      } else {
        SimpleLogger().info("No active survey found.");
      }
    });
  }

  /// Sets up timers for checking if device is approved and if there is active survey.
  Future<void> _setupTimers() async {
    SimpleLogger().info("Initializing default screen timers...");
    await _checkDeviceApproval();
    await _pollActiveSurvey();
  }

  @override
  void initState() {
    super.initState();
    _setupTimers();
  }

  @override
  void dispose() {
    _surveyNavigationTimer.cancel();
    _deviceApprovalTimer?.cancel();
    super.dispose();
  }

  void _handleManagementButton() {
    if (_clicks >= 10) {
      _surveyNavigationTimer.cancel();
      Navigator.push(
        context,
        MaterialPageRoute<ManagementScreen>(
            builder: (context) => const ManagementScreen()),
      ).then((_) => _setupTimers());
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
              height: 100,
              child: TextButton(
                onPressed: _handleManagementButton,
                style: ButtonStyle(
                  overlayColor: MaterialStateProperty.all(Colors.transparent),
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
