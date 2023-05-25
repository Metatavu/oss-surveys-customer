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

      child.replaceWith(_insertPageProperty(
          child, foundProperty, layoutVariable, mediaFilesMap));
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
        child.attributes["onClick"] = '''(function () {
          ${SurveyScreen.nextButtonMessageChannel}.postMessage($pageNumber + 1);
        })();
        return false;''';
      } else if (dataComponent == "question") {
        _handleQuestionElement(
          child,
          options,
        );
      }
      updatedChildren.add(child);
    }

    return updatedChildren;
  }

  /// Adds options to question element
  static void _handleQuestionElement(
    Element element,
    List<surveys_api.PageQuestionOption>? options,
  ) {
    if (options == null) return;

    element.attributes["style"] =
        "width: 100%; display:flex; flex:1; flex-direction: column; gap: 6rem; justify-content: center; margin-top: 10%;";
    element.children.addAll(options.map((e) {
      Element optionElement = Element.html(
          "<button style='margin-bottom: 3rem; width: 100%; height: 150px; font-size: 2.5rem; color: #fff; background: transparent; border: 20px solid #fff; font-family: SBonusText-Bold;'>${e.questionOptionValue}</button>");
      optionElement.attributes["onClick"] = '''(function () {
        ${SurveyScreen.selectOptionChannel}.postMessage("${e.id}");
      })();
      return false;''';

      return optionElement;
    }));
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
        var styles = element.attributes["style"];
        if (element.localName == "h1") {
          element.attributes["style"] = "$styles font-size: 7rem;";
        } else if (element.localName == "p") {
          element.attributes["style"] = "$styles font-size: 4rem;";
        }
        element.text = pageProperty.value.toString();

        return element;
      case surveys_api.LayoutVariableType.IMAGE_URL:
        if (element.localName == "img") {
          element.attributes["src"] = mediaFilesMap[pageProperty.key] ?? "";
        } else if (element.localName == "div") {
          var styles = element.attributes["style"];
          element.attributes["style"] =
              "${styles ?? ""}background-image: url('file://${mediaFilesMap[pageProperty.key]}')";
        }

        return element;
    }

    return element;
  }

  /// Wraps given [html] inside a wrapper
  static Document _wrapTemplate(String html) {
    return parse(
      '''
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
            }
          </style>
        </head>
        <body>
          $html
        </body>
      </html>
    ''',
    );
  }
}
