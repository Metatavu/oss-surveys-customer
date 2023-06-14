import "dart:async";
import "dart:convert";
import "package:async/async.dart";
import "package:flutter/material.dart";
import "package:list_ext/list_ext.dart";
import "package:oss_surveys_customer/database/dao/pages_dao.dart";
import "package:oss_surveys_customer/database/dao/surveys_dao.dart";
import "package:oss_surveys_customer/database/database.dart" as database;
import "package:oss_surveys_customer/main.dart";
import "package:oss_surveys_customer/screens/management_screen.dart";
import "package:oss_surveys_customer/utils/answer_controller.dart";
import "package:webview_flutter/webview_flutter.dart";
import "package:flutter_gen/gen_l10n/app_localizations.dart";
import "default_screen.dart";
import "package:oss_surveys_api/oss_surveys_api.dart" as surveys_api;

/// Survey screen
class SurveyScreen extends StatefulWidget {
  const SurveyScreen({super.key, required this.survey});

  final database.Survey survey;

  static const nextButtonMessageChannel = "NextButton";
  static const selectOptionChannel = "SelectOption";

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
  final List<String> _selectedOptions = [];
  late WebViewController _controller;
  late RestartableTimer _timeoutTimer;
  int _clicks = 0;
  Timer? _surveyNavigationTimer;

  /// Navigates the survey to next page
  void _navigateToPage(int pageNumber) {
    setState(() {
      _currentPageNumber =
          pageNumber > _pages.maxOf((element) => element.pageNumber)
              ? 1
              : pageNumber;
      _controller
          .loadHtmlString(_getPage()?.html ?? "No page found")
          .then((_) => logger.info("Loaded page $_currentPageNumber"));
    });
    _timeoutTimer.reset();
  }

  /// Callback function for handling next page button click [message] from the WebView
  void _handleNextPageButton(JavaScriptMessage message) async {
    database.Page? page = _getPage();
    if (page!.questionType == surveys_api.PageQuestionType.MULTI_SELECT.name) {
      _navigateToPage(_currentPageNumber + 1);
      if (_selectedOptions.isNotEmpty) {
        AnswerController.submitAnswer(
          jsonEncode(_selectedOptions),
          page,
          _survey.externalId,
        );
        _selectedOptions.clear();
      }
    }
    if (int.tryParse(message.message) != null) {
      _navigateToPage(int.parse(message.message));
    }
  }

  /// Callback function for handling option select [message] from the WebView
  void _handleOptionSelect(JavaScriptMessage message) async {
    switch (_getPage()?.questionType) {
      case "SINGLE_SELECT":
        _handleSingleSelectOption(message.message);
        break;
      case "MULTI_SELECT":
        _handleMultiSelectOption(message.message);
        break;
    }
  }

  /// Callback function for handling multi select option clicking [message] from the WebView
  void _handleMultiSelectOption(String optionId) async {
    if (_selectedOptions.contains(optionId)) {
      _selectedOptions.retainWhere((element) => element != optionId);
      logger.info("Removed option $optionId from multi select options");
    } else {
      _selectedOptions.add(optionId);
      logger.info("Added option $optionId to multi select options");
    }
    logger.info("Selected options: $_selectedOptions");
  }

  /// Callback function for handling single select option clicking [message] from the WebView
  void _handleSingleSelectOption(String optionId) async {
    database.Page page = _getPage()!;
    _navigateToPage(_currentPageNumber + 1);
    AnswerController.submitAnswer(
      optionId,
      page,
      _survey.externalId,
    );
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

  /// Callback function for timeout timer.
  ///
  /// Navigates back to surveys first page after timeout.
  void _handleTimeout() {
    logger.info("Timeout ${widget.survey.timeout}");
    if (_currentPageNumber != 1) {
      setState(() => _currentPageNumber = 1);
      _controller
          .loadHtmlString(_getPage()?.html ?? "No page found")
          .then((_) => logger.info("Loaded page 1"));
    }
  }

  void _setupTimers() {
    _timeoutTimer = RestartableTimer(
      Duration(seconds: widget.survey.timeout),
      _handleTimeout,
    );
  }

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..addJavaScriptChannel(
        SurveyScreen.nextButtonMessageChannel,
        onMessageReceived: _handleNextPageButton,
      )
      ..addJavaScriptChannel(
        SurveyScreen.selectOptionChannel,
        onMessageReceived: _handleOptionSelect,
      );

    _subscription = streamController.stream.listen(_handleStreamEvent);
    _setupTimers();
    _loadPages();
    logger.info("Survey screen init ${widget.survey.title}");
  }

  void _handleManagementButton() {
    if (_clicks >= 10) {
      _surveyNavigationTimer?.cancel();
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const ManagementScreen()),
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
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Center(
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
          if (!_loading)
            Positioned(
              left: 0,
              top: 0,
              child: SizedBox(
                width: MediaQuery.of(context).size.width,
                height: 50,
                child: TextButton(
                  onPressed: _handleManagementButton,
                  style: ButtonStyle(
                    backgroundColor: MaterialStateProperty.all(
                      Colors.transparent,
                    ),
                    overlayColor: MaterialStateProperty.all(
                      Colors.transparent,
                    ),
                  ),
                  child: const SizedBox(),
                ),
              ),
            ),
        ],
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
