import "package:html/dom.dart";
import "package:html/parser.dart";
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

    if (document.body == null) {
      return "";
    }

    if (document.body?.children == null) {
      return "";
    }
    var documentClone = document.clone(true);
    var bodyClone = document.body!.clone(true);
    bodyClone.attributes["style"] = "margin: 0; padding: 0;";
    bodyClone.children.clear();
    bodyClone.children.addAll(
      _handleChildren(
        document.body!.children,
        page.question?.options.toList(),
        page.properties!.toList(),
        page.layoutVariables!.toList(),
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
    List<surveys_api.PageQuestionOption>? options,
    List<surveys_api.PageProperty> pageProperties,
    List<surveys_api.LayoutVariable> layoutVariables,
    Map<String, String> mediaFilesMap,
    int pageNumber,
  ) {
    List<Element> updatedChildren = [];
    for (Element child in children) {
      surveys_api.PageProperty? foundProperty;
      surveys_api.LayoutVariable? layoutVariable;
      try {
        foundProperty =
            pageProperties.firstWhere((property) => property.key == child.id);
        layoutVariable =
            layoutVariables.firstWhere((variable) => variable.key == child.id);
      } catch (e) {}
      child.replaceWith(_insertPageProperty(
          child, foundProperty, layoutVariable, mediaFilesMap));
      child.children.addAll(
        _handleChildren(
          child.children,
          options,
          pageProperties,
          layoutVariables,
          mediaFilesMap,
          pageNumber,
        ),
      );

      var dataComponent = child.attributes["data-component"];

      if (dataComponent == "next-button") {
        child.attributes["onClick"] = '''(function () {
          ${SurveyScreen.nextButtonMessageChannel}.postMessage($pageNumber + 1);
        })();
        return false;''';
      } else if (dataComponent == "question") {
        if (options != null) {
          _handleQuestionElement(
            child,
            options,
          );
        }
      }
      updatedChildren.add(child);
    }

    return updatedChildren;
  }

  /// Adds options to question element
  static void _handleQuestionElement(
    Element element,
    List<surveys_api.PageQuestionOption> options,
  ) {
    element.attributes["style"] =
        "width: 100%; display:flex; flex:1; flex-direction: column; gap: 6rem; justify-content: center; margin-top: 10%;";
    element.children.addAll(
      options.map((e) => Element.html(
          "<button style='margin-bottom: 6rem; width: 100%; height: 250px; font-size: 6rem; color: #fff; background: transparent; border: 20px solid #fff; font-family: SBonusText-Bold;'>${e.questionOptionValue}</button>")),
    );
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
        element.text = pageProperty.value.toString();

        return element;
      case surveys_api.LayoutVariableType.IMAGE_URL:
        if (element.localName == "img") {
          element.attributes["src"] = mediaFilesMap[pageProperty.key] ?? "";
        } else if (element.localName == "div") {
          var styles = element.attributes["style"];
          if (styles != null) {
            element.attributes["style"] =
                "$styles background-image: url('${mediaFilesMap[pageProperty.key]}');";
          } else {
            element.attributes["style"] =
                "background-image: url('${mediaFilesMap[pageProperty.key]}');";
          }
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
