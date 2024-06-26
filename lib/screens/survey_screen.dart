import "dart:async";
import "dart:convert";
import "package:async/async.dart";
import "package:flutter/material.dart";
import "package:list_ext/list_ext.dart";
import "package:oss_surveys_customer/database/dao/pages_dao.dart";
import "package:oss_surveys_customer/database/dao/surveys_dao.dart";
import "package:oss_surveys_customer/database/database.dart" as database;
import "package:oss_surveys_customer/l10n/gen_l10n/app_localizations.dart";
import "package:oss_surveys_customer/main.dart";
import "package:oss_surveys_customer/screens/management_screen.dart";
import "package:oss_surveys_customer/utils/answer_controller.dart";
import "package:simple_logger/simple_logger.dart";
import "package:webview_flutter/webview_flutter.dart";
import "default_screen.dart";
import "package:oss_surveys_api/oss_surveys_api.dart" as surveys_api;

/// Survey screen
class SurveyScreen extends StatefulWidget {
  final database.Survey survey;
  const SurveyScreen({super.key, required this.survey});

  static const nextButtonMessageChannel = "NextButton";
  static const selectOptionChannel = "SelectOption";

  @override
  State<SurveyScreen> createState() => _SurveyScreenState();
}

/// Survey Screen state
class _SurveyScreenState extends State<SurveyScreen> {
  _SurveyScreenState();

  late StreamSubscription<database.Survey?> _subscription;
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
          .loadHtmlString(_getPage(_pages)?.html ?? "No page found")
          .then((_) => SimpleLogger().info("Loaded page $_currentPageNumber"));
    });
    _timeoutTimer.reset();
  }

  /// Callback function for handling next page button click [message] from the WebView
  void _handleNextPageButton(JavaScriptMessage message) async {
    database.Page? page = _getPage(_pages);
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
    switch (_getPage(_pages)?.questionType) {
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
      SimpleLogger().info("Removed option $optionId from multi select options");
    } else {
      _selectedOptions.add(optionId);
      SimpleLogger().info("Added option $optionId to multi select options");
    }
    SimpleLogger().info("Selected options: $_selectedOptions");
  }

  /// Callback function for handling single select option clicking [message] from the WebView
  void _handleSingleSelectOption(String optionId) async {
    database.Page page = _getPage(_pages)!;
    _navigateToPage(_currentPageNumber + 1);
    AnswerController.submitAnswer(
      optionId,
      page,
      _survey.externalId,
    );
  }

  /// Gets current page from [_pages] list
  database.Page? _getPage(List<database.Page> pages) {
    return pages.firstWhereOrNull(
        (element) => element.pageNumber == _currentPageNumber);
  }

  /// Navigates to given [target] screen
  void _navigateTo<T extends StatefulWidget>(T target) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute<T>(
        builder: (context) => target,
      ),
    );
  }

  /// Callback method for handling [event] pushed to the stream
  Future<void> _handleStreamEvent(dynamic event) async {
    SimpleLogger().info("Received stream event.");
    if (event is database.Survey) {
      database.Survey? activeSurvey = await surveysDao.findActiveSurvey();
      if (activeSurvey != null &&
          widget.survey.externalId != activeSurvey.externalId) {
        _navigateTo(SurveyScreen(survey: activeSurvey));
      } else if (activeSurvey == null) {
        _navigateTo(const DefaultScreen());
      }
    } else if (event == null) {
      SimpleLogger().info("Received null event, going to default screen...");
      _navigateTo(const DefaultScreen());
    }
  }

  /// Loads pages from database, sets them in state and loads the first page in the WebView
  Future<void> _loadPages() async {
    var activeSurvey = await surveysDao.findActiveSurvey();
    if (activeSurvey == null) {
      SimpleLogger().info("No active survey found, navigating back...");
      _navigateTo(const DefaultScreen());
      return;
    }
    var foundPages = await pagesDao.listPagesBySurveyId(activeSurvey.id);
    setState(() {
      _survey = activeSurvey;
      _pages = foundPages;
      _controller
          .loadHtmlString(_getPage(foundPages)?.html ?? "No page found")
          .then((_) => SimpleLogger().info("Loaded page 1"));
      _loading = false;
    });
  }

  /// Callback function for timeout timer.
  ///
  /// Navigates back to surveys first page after timeout.
  void _handleTimeout() {
    SimpleLogger().info("Timeout ${widget.survey.timeout}");
    if (_currentPageNumber != 1) {
      setState(() => _currentPageNumber = 1);
      _controller
          .loadHtmlString(_getPage(_pages)?.html ?? "No page found")
          .then((_) => SimpleLogger().info("Loaded page 1"));
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
    SimpleLogger().info("Survey screen init ${widget.survey.title}");
  }

  void _handleManagementButton() {
    if (_clicks >= 9) {
      _surveyNavigationTimer?.cancel();
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
