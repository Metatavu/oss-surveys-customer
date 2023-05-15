import "package:html/dom.dart";
import "package:html/parser.dart";
import "package:oss_surveys_api/oss_surveys_api.dart" as surveys_api;

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

    Document document = _deserializeHTML(page.layoutHtml!);

    if (document.body == null) {
      return "";
    }

    if (document.body?.children == null) {
      return "";
    }
    var documentClone = document.clone(true);
    var bodyClone = document.body!.clone(true);
    bodyClone.children.clear();
    bodyClone.children.addAll(_handleChildren(
      document.body!.children,
      page.properties!.toList(),
      mediaFilesMap,
    ));

    documentClone.body!.replaceWith(bodyClone);

    return _serializeHTML(documentClone);
  }

  /// Handles children
  static List<Element> _handleChildren(
    List<Element> children,
    List<surveys_api.PageProperty> pageProperties,
    Map<String, String> mediaFilesMap,
  ) {
    List<Element> updatedChildren = [];
    for (Element child in children) {
      surveys_api.PageProperty? foundProperty;
      try {
        foundProperty =
            pageProperties.firstWhere((element) => element.key == child.id);
      } catch (e) {}
      var updatedChild = child.clone(true);
      updatedChild.children.clear();
      updatedChild.children.addAll(_handleChildren(
        child.children,
        pageProperties,
        mediaFilesMap,
      ));
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

  /// Deserializes HTML from [html] into a Document
  static Document _deserializeHTML(String html) {
    return parse(html);
  }

  /// Serializes HTML from [document] into a String
  static String _serializeHTML(Document document) {
    document.querySelectorAll("h1").forEach((element) => print(element.text));

    return document.outerHtml;
  }

  /// Convert Options from [pageProperties] into HTML
  static String _convertOptions(List<surveys_api.PageProperty> pageProperties) {
    String html = "";
    for (surveys_api.PageProperty pageProperty in pageProperties) {
      html +=
          "<div><button style=\"width: 100%; height: 100px; font-size: 5rem;\">${pageProperty.value}</button></div>";
    }

    return html;
  }

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
        element.innerHtml = _convertOptions(
          pageProperty.value as List<surveys_api.PageProperty>,
        );
        break;
    }
  }
}
