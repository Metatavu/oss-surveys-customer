import "package:flutter/material.dart";
import "package:oss_surveys_customer/database/dao/pages_dao.dart";
import "package:oss_surveys_customer/database/database.dart" as database;
import "package:oss_surveys_customer/database/dao/surveys_dao.dart";
import "package:oss_surveys_customer/main.dart";
import "package:webview_flutter/webview_flutter.dart";

/// Survey screen
class SurveyScreen extends StatefulWidget {
  const SurveyScreen({super.key, required this.survey});

  final database.Survey survey;

  @override
  State<SurveyScreen> createState() => _SurveyScreenState();
}

/// Survey Screen state
class _SurveyScreenState extends State<SurveyScreen> {
  int currentPageNumber = 1;
  List<database.Page> pages = [];
  WebViewController controller = WebViewController()
    ..setJavaScriptMode(JavaScriptMode.unrestricted);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      var foundPages = await pagesDao.listPagesBySurveyId(widget.survey.id);

      setState(() {
        pages = foundPages;
        controller.loadHtmlString(foundPages[0].html).then((_) {
          logger.info("Loaded page 1");
        });
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: WebViewWidget(controller: controller));
  }
}
