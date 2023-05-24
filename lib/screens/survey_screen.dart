import "dart:async";
import "package:flutter/material.dart";
import "package:list_ext/list_ext.dart";
import "package:oss_surveys_customer/database/dao/pages_dao.dart";
import "package:oss_surveys_customer/database/dao/surveys_dao.dart";
import "package:oss_surveys_customer/database/database.dart" as database;
import "package:oss_surveys_customer/main.dart";
import "package:webview_flutter/webview_flutter.dart";
import "package:flutter_gen/gen_l10n/app_localizations.dart";
import "default_screen.dart";

/// Survey screen
class SurveyScreen extends StatefulWidget {
  const SurveyScreen({super.key, required this.survey});

  final database.Survey survey;

  static const nextButtonMessageChannel = "NextButton";
  static const singleSelectOptionChannel = "SingleSelect";

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

  /// Callback function for handling next page button click [message] from the WebView
  void _handleNextPage(JavaScriptMessage message) {
    if (int.tryParse(message.message) != null) {
      setState(() {
        if (_currentPageNumber ==
            _pages.maxOf((element) => element.pageNumber)) {
          _currentPageNumber = 1;
        } else {
          _currentPageNumber++;
        }
        _controller
            .loadHtmlString(_getPage()?.html ?? "No page found")
            .then((_) => logger.info("Loaded page $_currentPageNumber"));
      });
    }
  }

  /// Gets current page from [_pages] list
  database.Page? _getPage() {
    return _pages.firstWhereOrNull(
        (element) => element.pageNumber == _currentPageNumber);
  }

  /// Navigates back to default screen
  void _navigateBack() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => const DefaultScreen(),
      ),
    );
  }

  /// Callback method for handling [event] pushed to the stream
  Future _handleStreamEvent(dynamic event) async {
    logger.info("Received stream event.");
    if (event is database.Survey) {
      if (event.id == widget.survey.id) {
        setState(() => _loading = true);
        database.Survey? foundSurvey =
            await surveysDao.findSurveyByExternalId(event.externalId);
        var foundPages = await pagesDao.listPagesBySurveyId(foundSurvey!.id);
        setState(() {
          _currentPageNumber = 1;
          _survey = foundSurvey;
          _pages = foundPages;
          _loading = false;
          _controller
              .loadHtmlString(_getPage()?.html ?? "No page found")
              .then((_) => logger.info("Loaded page 1"));
        });
      }
    }
    if (event == null) {
      logger.info("Received null event, going to default screen...");
      _navigateBack();
    }
  }

  /// Loads pages from database, sets them in state and loads the first page in the WebView
  Future _loadPages() async {
    var foundPages = await pagesDao.listPagesBySurveyId(widget.survey.id);
    setState(() {
      _survey = widget.survey;
      _pages = foundPages;
      _controller
          .loadHtmlString(_getPage()?.html ?? "No page found")
          .then((_) => logger.info("Loaded page 1"));
      _loading = false;
    });
  }

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..addJavaScriptChannel(
        SurveyScreen.nextButtonMessageChannel,
        onMessageReceived: _handleNextPage,
      );

    _subscription = streamController.stream.listen(_handleStreamEvent);
    _loadPages();
    logger.info("Survey screen init ${widget.survey.title}");
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
  void deactivate() {
    super.deactivate();
    _subscription.cancel();
  }

  @override
  void dispose() {
    super.dispose();
    _subscription.cancel();
  }
}
