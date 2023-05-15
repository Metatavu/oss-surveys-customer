import "package:built_collection/built_collection.dart";
import "package:flutter_test/flutter_test.dart";
import "package:oss_surveys_api/oss_surveys_api.dart";
import "package:oss_surveys_customer/utils/html_controller.dart";

void main() {
  test("html_process_test", () {});

  String html =
      "<div style='height: 100vh; width: 100vw; background-color: #00AA46; color: #FFFFFF; display: flex; flex: 1; flex-direction: column; padding: 10%; box-sizing: border-box;'><div style='display: flex; flex: 1; flex-direction: column;'><h1 id='60a278ff-3902-4826-b81f-7cc09eac6db9' style='margin: 0; padding: 0; text-transform: uppercase; font-size: 12rem; font-family: SBonusDisplay-Black;'>Otsikko</h1><p style='font-family: SBonusDisplay-Regular; font-size: 8rem; line-height: 150%;'>Infoteksti</p></div><button style='width: 100%; background-color: transparent; border: 20px solid #FFFFFF; color: #FFFFFF; height: 250px; font-family: SBonusText-Bold; font-size: 6rem;'>Seuraava</button></div>";

  var pagePropertyBuilder = PagePropertyBuilder();
  pagePropertyBuilder.key = "60a278ff-3902-4826-b81f-7cc09eac6db9";
  pagePropertyBuilder.value = "Testiteksti";
  pagePropertyBuilder.type = PagePropertyType.TEXT;

  List<PageProperty> pageProperties = [
    pagePropertyBuilder.build(),
  ];

  var pageBuilder = DeviceSurveyPageDataBuilder();
  pageBuilder.layoutHtml = html;
  pageBuilder.properties = ListBuilder(pageProperties);

  String processedHtml =
      HTMLController.processSurveyPage(pageBuilder.build(), {});

  expect(
    true,
    processedHtml.contains(
      "<h1 id='60a278ff-3902-4826-b81f-7cc09eac6db9' style='margin: 0; padding: 0; text-transform: uppercase; font-size: 12rem; font-family: SBonusDisplay-Black;'>Testiteksti</h1>",
    ),
  );
}
