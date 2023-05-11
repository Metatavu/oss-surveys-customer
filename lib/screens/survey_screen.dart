import "package:flutter/material.dart";
import "package:oss_surveys_customer/database/database.dart";
import "package:oss_surveys_customer/database/dao/surveys_dao.dart";

/// Survey screen
class SurveyScreen extends StatefulWidget {
  const SurveyScreen({super.key});

  @override
  State<SurveyScreen> createState() => _SurveyScreenState();
}

/// Survey Screen state
class _SurveyScreenState extends State<SurveyScreen> {
  late Survey survey;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance!.addPostFrameCallback((_) {
      surveysDao.findActiveSurvey().then((value) {
        if (value == null) {
          Navigator.pop(context);
        }
        setState(() {
          survey = value!;
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
        ),
      ),
    );
  }
}
