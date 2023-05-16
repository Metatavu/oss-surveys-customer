import "dart:async";
import "package:flutter/material.dart";
import "package:list_ext/list_ext.dart";
import "package:oss_surveys_customer/database/dao/pages_dao.dart";
import "package:oss_surveys_customer/database/dao/surveys_dao.dart";
import "package:oss_surveys_customer/database/database.dart" as database;
import "package:oss_surveys_customer/main.dart";
import "package:webview_flutter/webview_flutter.dart";
import "package:flutter_gen/gen_l10n/app_localizations.dart";

/// Survey screen
class SurveyScreen extends StatefulWidget {
  const SurveyScreen({super.key, required this.survey});

  final database.Survey survey;

  @override
  State<SurveyScreen> createState() => _SurveyScreenState();
}

/// Survey Screen state
class _SurveyScreenState extends State<SurveyScreen> {
  _SurveyScreenState();

  late StreamSubscription _subscription;
  bool _loading = true;
  late database.Survey _survey;
  int _currentPageNumber = 1;
  List<database.Page> _pages = [];
  late WebViewController _controller;

  /// TODO: ADD DOCS
  void _handleNextPage(JavaScriptMessage message) {
    if (int.tryParse(message.message) != null) {
      setState(() {
        _currentPageNumber++;
        _controller
            .loadHtmlString(_getPage()?.html ?? "No page found")
            .then((_) {
          logger.info("Loaded page $_currentPageNumber");
        });
      });
    }
  }

  database.Page? _getPage() {
    return _pages.firstWhereOrNull(
        (element) => element.pageNumber == _currentPageNumber);
  }

  /// Callback method for handling [event] pushed to the stream
  Future _handleStreamEvent(dynamic event) async {
    if (event is database.Survey) {
      if (event.id == widget.survey.id) {
        setState(() {
          _loading = true;
        });
        database.Survey? foundSurvey =
            await surveysDao.findSurveyByExternalId(event.externalId);
        var foundPages = await pagesDao.listPagesBySurveyId(foundSurvey!.id);
        setState(() {
          _survey = foundSurvey;
          _pages = foundPages;
          _loading = false;
          _controller
              .loadHtmlString(_getPage()?.html ?? "No page found")
              .then((_) {
            logger.info("Loaded page 1");
          });
        });
      }
    }
  }

  /// TODO: ADD DOCS
  Future _loadPages() async {
    var foundPages = await pagesDao.listPagesBySurveyId(widget.survey.id);
    setState(() {
      _survey = widget.survey;
      _pages = foundPages;
      _controller.loadHtmlString(foundPages[0].html).then((_) {
        logger.info("Loaded page 1");
      });
      _loading = false;
    });
  }

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..addJavaScriptChannel("NextButton", onMessageReceived: _handleNextPage);

    _subscription = streamController.stream.listen(_handleStreamEvent);
    _loadPages();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).primaryColor,
      body: Center(
        child: _loading
            ? SizedBox(
                width: MediaQuery.of(context).size.width / 2,
                height: MediaQuery.of(context).size.width / 2,
                child: Column(
                  children: [
                    const CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 20,
                    ),
                    Text(
                      AppLocalizations.of(context)!.loadingSurvey,
                      style: const TextStyle(
                          fontFamily: "S-Bonus-Regular",
                          color: Color(0xffffffff),
                          fontSize: 30),
                    )
                  ],
                ),
              )
            : WebViewWidget(controller: _controller),
      ),
    );
  }

  @override
  void deactivate() async {
    await _subscription.cancel();
    super.deactivate();
  }

  @override
  void dispose() async {
    await _subscription.cancel();
    super.dispose();
  }
}
