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
        page.properties!.toList(),
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
    List<surveys_api.PageProperty> pageProperties,
    Map<String, String> mediaFilesMap,
    int pageNumber,
  ) {
    List<Element> updatedChildren = [];
    for (Element child in children) {
      surveys_api.PageProperty? foundProperty;
      try {
        foundProperty =
            pageProperties.firstWhere((element) => element.key == child.id);
      } catch (e) {
        if (child.id.isNotEmpty) {
          var pagePropertyBuilder = surveys_api.PagePropertyBuilder();
          pagePropertyBuilder.key = child.id;
          pagePropertyBuilder.value = child.text + pageNumber.toString();
          pagePropertyBuilder.type = surveys_api.PagePropertyType.TEXT;
          foundProperty = pagePropertyBuilder.build();
        }
      }
      var updatedChild = child.clone(true);
      updatedChild.children.clear();
      updatedChild.children.addAll(
        _handleChildren(
          child.children,
          pageProperties,
          mediaFilesMap,
          pageNumber,
        ),
      );

      var dataComponent = updatedChild.attributes["data-component"];

      if (dataComponent == "next-button") {
        updatedChild.attributes["onClick"] = '''(function () {
          ${SurveyScreen.nextButtonMessageChannel}.postMessage($pageNumber + 1);
        })();
        return false;''';
      } else if (dataComponent == "question") {
        _handleQuestionElement(
          updatedChild,
          pageProperties,
        );
      }
      if (foundProperty != null) {
        _insertPageProperty(
          updatedChild,
          foundProperty,
          mediaFilesMap,
        );
      }
      updatedChildren.add(updatedChild);
    }

    return updatedChildren;
  }

  /// Adds options to question element
  static void _handleQuestionElement(
    Element element,
    List<surveys_api.PageProperty> pageProperties,
  ) {
    element.attributes["style"] =
        "width:  100%; display:flex; flex:1; flex-direction: column; gap: 6rem; justify-content: center; margin-top: 10%;";
    element.children.addAll(
      (pageProperties
                  .firstWhereOrNull((element) => element.key == "OPTIONS")
                  ?.value ??
              "")
          .split(",")
          .map(
            (e) => e.isNotEmpty
                ? Element.html(
                    "<div style='margin-bottom: 6rem;'><button style='width: 100%; height: 250px; font-size: 6rem; color: #fff; background: transparent; border: 20px solid #fff'>${e.replaceAll(RegExp('[^A-Za-z]'), '')}</button></div>")
                : Element.html("<div></div>"),
          ),
    );
  }

  /// Serializes HTML from [document] into a String
  static String _serializeHTML(Document document) => document.outerHtml;

  /// Inserts PageProperty value into HTML
  static void _insertPageProperty(
    Element element,
    surveys_api.PageProperty pageProperty,
    Map<String, String> mediaFilesMap,
  ) {
    switch (pageProperty.type) {
      case surveys_api.PagePropertyType.TEXT:
        element.text = pageProperty.value.toString();
        break;
      case surveys_api.PagePropertyType.IMAGE_URL:
        element.attributes["src"] = mediaFilesMap[pageProperty.key] ?? "";
        break;
      case surveys_api.PagePropertyType.OPTIONS:
        break;
    }
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
