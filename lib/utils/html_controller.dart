import "package:html/dom.dart";
import "package:html/parser.dart";
import "package:list_ext/list_ext.dart";
import "package:oss_surveys_api/oss_surveys_api.dart" as surveys_api;
import "../screens/survey_screen.dart";

/// HTML Controller class
///
/// This class is used to convert PageProperties into HTML
class HTMLController {
  /// Processes Device Survey Page [page] into displayable HTML
  ///
  /// Inserts offlined media paths into HTML from [mediaFilesMap]
  static String processSurveyPage(
    surveys_api.DeviceSurveyPageData page,
    Map<String, String> mediaFilesMap,
  ) {
    if (page.layoutHtml == null) {
      return "";
    }

    Document document = _wrapTemplate(page.layoutHtml!);

    if (document.body == null) return "";
    if (document.body?.children == null) return "";

    var documentClone = document.clone(true);
    var bodyClone = document.body!.clone(true);
    bodyClone.children.clear();
    bodyClone.children.addAll(
      _handleChildren(
        document.body!.children,
        page,
        page.question?.options.toList(),
        mediaFilesMap,
        page.pageNumber!,
      ),
    );

    documentClone.body!.replaceWith(bodyClone);

    return _serializeHTML(documentClone);
  }

  /// Handles children
  static List<Element> _handleChildren(
    List<Element> children,
    surveys_api.DeviceSurveyPageData page,
    List<surveys_api.PageQuestionOption>? options,
    Map<String, String> mediaFilesMap,
    int pageNumber,
  ) {
    List<Element> updatedChildren = [];
    for (Element child in children) {
      surveys_api.PageProperty? foundProperty = page.properties
          ?.firstWhereOrNull((property) => property.key == child.id);
      surveys_api.LayoutVariable? layoutVariable = page.layoutVariables
          ?.firstWhereOrNull((variable) => variable.key == child.id);

      child.replaceWith(
        _insertPageProperty(
          child,
          foundProperty,
          layoutVariable,
          mediaFilesMap,
        ),
      );
      child.children.addAll(
        _handleChildren(
          child.children,
          page,
          options,
          mediaFilesMap,
          pageNumber,
        ),
      );

      var dataComponent = child.attributes["data-component"];

      if (dataComponent == "next-button") {
        bool nextButtonVisible = page.nextButtonVisible ?? false;

        if (!nextButtonVisible) {
          child.attributes["style"] = "display: none;";
        }

        child.attributes["ontouchstart"] = "addActive(this)";
        child.attributes["ontouchend"] = "nextPage(this, $pageNumber)";
      } else if (dataComponent == "question") {
        _handleQuestionElement(
          child,
          page,
        );
      }
      updatedChildren.add(child);
    }

    return updatedChildren;
  }

  /// Adds options to question element
  static void _handleQuestionElement(
    Element element,
    surveys_api.DeviceSurveyPageData page,
  ) {
    if (page.question?.options == null) return;

    element.children.addAll(page.question!.options.map((e) {
      switch (page.question!.type) {
        case surveys_api.PageQuestionType.SINGLE_SELECT:
          return _createSingleSelect(element, e);
        case surveys_api.PageQuestionType.MULTI_SELECT:
          return _createMultiSelect(e);
        default:
          return Element.tag("span");
      }
    }));
  }

  /// Creates a single select option button from [option]
  @Deprecated(
      "Used to support old format of layouts. Use _createSingleSelectDiv with new layouts.")
  static Element _createSingleSelectButton(
    surveys_api.PageQuestionOption option,
  ) {
    Element optionElement = Element.html('''
      <button class="option">${option.questionOptionValue}</button>
    ''');
    _addSingleSelectTouchEvents(optionElement, option.id!);

    return optionElement;
  }

  /// Creates a single select option div from [option]
  static Element _createSingleSelectDiv(
    surveys_api.PageQuestionOption option,
  ) {
    Element divElement =
        Element.html("<div class=\"option\" id=\"${option.id}\"></option>");
    List<Element> optionElements =
        parse(option.questionOptionValue).body!.children;
    for (var element in optionElements) {
      _addSingleSelectTouchEvents(element, option.id!);
    }
    divElement.children.addAll(optionElements);

    return divElement;
  }

  /// Adds touch event listeners to single select option [element]
  static void _addSingleSelectTouchEvents(Element element, String optionId) {
    element.attributes["ontouchstart"] = "addActive(this)";
    element.attributes["ontouchend"] = "selectSingleOption(this, '$optionId')";
  }

  /// Creates a single select [option]
  ///
  /// Legacy layouts use plain text as options, new layouts use HTML.
  /// Therefore this method interprets whether the option is HTML or plain text and creates the option accordingly.
  static Element _createSingleSelect(
    Element element,
    surveys_api.PageQuestionOption option,
  ) {
    switch (option.questionOptionValue.startsWith("<")) {
      case true:
        return _createSingleSelectDiv(option);
      default:
        return _createSingleSelectButton(option);
    }
  }

  /// Creates a multi select [option]
  static Element _createMultiSelect(surveys_api.PageQuestionOption option) {
    Element optionElement =
        Element.html("<div class=\"multi-option\" id=\"${option.id}\"></div>");
    final childElement = Element.tag("div");
    childElement.innerHtml = option.questionOptionValue;
    optionElement.children.add(childElement);

    optionElement.attributes["ontouchend"] =
        "selectMultiOption('${option.id}')";

    return optionElement;
  }

  /// Serializes HTML from [document] into a String
  static String _serializeHTML(Document document) => document.outerHtml;

  /// Inserts PageProperty value into HTML
  static Element _insertPageProperty(
    Element element,
    surveys_api.PageProperty? pageProperty,
    surveys_api.LayoutVariable? layoutVariable,
    Map<String, String> mediaFilesMap,
  ) {
    if (pageProperty == null || layoutVariable == null) {
      return element;
    }

    switch (layoutVariable.type) {
      case surveys_api.LayoutVariableType.TEXT:
        if (element.localName == "div") {
          element.children.clear();
          element.children.addAll(parse(pageProperty.value).body!.children);
        }

        return element;
      case surveys_api.LayoutVariableType.IMAGE_URL:
        if (element.localName == "img") {
          element.attributes["src"] =
              "file://${mediaFilesMap[pageProperty.key] ?? ""}";
        } else if (element.localName == "div") {
          var styles = element.attributes["style"];
          element.attributes["style"] = '''
            ${styles ?? ""}background-image: url('file://${mediaFilesMap[pageProperty.key]}')
          ''';
        }

        return element;
    }

    return element;
  }

  /// Wraps given [html] inside a wrapper
  static Document _wrapTemplate(String html) {
    return parse('''
      <!DOCTYPE html>
      <html lang="en">
        <head>
          <meta charset="UTF-8">
          <meta http-equiv="X-UA-Compatible" content="IE=edge">
          <meta name="viewport" content="width=device-width, initial-scale=1.0">
          <title>Page</title>
          <link rel="stylesheet" href="https://cdn.metatavu.io/fonts/sok/fonts/stylesheet.css"/>
          <meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
          <style>
            body {
              margin: 0;
              padding: 0;
              user-select: none;
              touch-action: none;
            }
            .page {
              height: 100vh;
              width: 100vw;
              background-color: #00AA46;
              color: #ffffff;
              display: flex;
              flex: 1;
              flex-direction: column;
              padding: 10% 215px 215px 10%;
              box-sizing: border-box;
              background-size: cover;
            }
            .page.text-shadow {
              text-shadow: 0px 0px 15px rgba(0, 0, 0, 0.75);
            }
            .logo-container {
              position: absolute;
              bottom: 0;
              right: 0;
              left: 0;
              height: 215px;
              display: flex;
              justify-content: center;
              align-items: center;
            }
            svg.logo {
              height: 140px;
            }
            .content {
              display: flex;
              flex: 1;
              flex-direction: column;
            }
            h1 {
              margin: 0;
              padding: 0;
              text-transform: uppercase;
              font-family: SBonusDisplay-Black;
            }
            h1.sm {
              font-size: 4rem;
            }
            h1.md {
              font-size: 5rem;
            }
            h1.lg {
              font-size: 6rem;
            }
            p {
              font-family: SBonusDisplay-Regular;
              font-size: 4rem;
              line-height: 150%;
            }
            .options {
              display: flex;
              flex: 1;
              flex-direction: column;
              gap: 5%;
              justify-content: center;
            }
            .img-wrapper {
              display: flex;
              flex: 1;
              justify-content: center;
              margin-top: 10%;
              width: 100%;
            }
            .option {
              width: 100%;
              box-sizing: border-box;
              padding: 30px 20px;
              font-size: 2.5rem;
              font-family: 'SBonusText-Bold';
              text-align: center;
              color: #fff;
              border: 4px solid #fff;
              margin-bottom: 5%;
            }
            .page.text-shadow .option {
              text-shadow: 0px 0px 15px rgba(0, 0, 0, 0.75);
              box-shadow: 0px 0px 30px rgba(0, 0, 0, 0.25);
              background: rgba(0,0,0,0.1);
            }
            .multi-option {
              position: relative;
              width: 100%;
              padding: 20px 0 20px 130px;
              box-sizing: border-box;
              font-size: 2.5rem;
              line-height: 150%;
              font-family: 'SBonusText-Bold';
              color: #fff;
              background-color: transparent;
              transition: background-color 0.2s ease-in-out;
              margin-bottom: 5%;
            }
            .page.text-shadow .multi-option {
              text-shadow: 0px 0px 15px rgba(0, 0, 0, 0.75);
            }
            .multi-option:before {
              content: "";
              position: absolute;
              left: 0;
              top: 50%;
              transform: translateY(-50%);
              height: 80px;
              width: 80px;
              border: 4px solid #fff;
              transition: background-color 0.2s ease-in-out;
              background-color: rgba(0, 0, 0, 0.1);
            }
            .multi-option.selected:before {
              background-color: rgba(0, 0, 0, 0.2);
            }
            .page.text-shadow .multi-option:before {
              background-color: rgba(0, 0, 0, 0.1);
            }
            .multi-option.selected:before, .page.text-shadow .multi-option.selected:before {
              background-color: rgba(0, 0, 0, 0.2);
            }
            .multi-option.selected:after {
              content: "✓";
              position: absolute;
              left: 26px;
              top: 50%;
              color: #fff;
              transform: translateY(-50%);
            }
            .next-button {
              background-color: transparent;
              border: none;
              color: #ffffff;
              height: 100%;
              width: 215px;
              position: absolute;
              top: 0;
              right: 0;
            }
            .next-button:focus, .option:focus {
              outline: none;
            }
            .next-button.active {
              background-color: rgba(0, 0, 0, 0.1);
            }
            .option.active {
              background-color: rgba(0, 0, 0, 0.2);
            }
            svg.next-icon {
              margin-top: 600px;
              height: 100px;
              width: 100px;
            }
          </style>
        </head>
        <body>
          $html
        </body>
        <script>
          var latestTouchEvent;

          function addActive(element) {
            element.classList.add('active');
          }

          function removeActive(element) {
            element.classList.remove('active');
          }

          function throttleTouch() {
            var currentTime = new Date().getTime();

            if (currentTime - (latestTouchEvent || 0) < 500) return true;

            latestTouchEvent = currentTime;
            return false;
          }

          function nextPage(element, pageNumber) {
            removeActive(element);

            if (throttleTouch()) return false;

            ${SurveyScreen.nextButtonMessageChannel}.postMessage(pageNumber + 1);
          }

          function selectSingleOption(element, optionId) {
            removeActive(element);

            if (throttleTouch()) return false;

            ${SurveyScreen.selectOptionChannel}.postMessage(optionId);
          }

          function selectMultiOption(optionId) {
            if (throttleTouch()) return false;

            document.getElementById(optionId).classList.toggle('selected');

            ${SurveyScreen.selectOptionChannel}.postMessage(optionId);
          }
        </script>
      </html>
    ''');
  }
}
