import "dart:io";
import "package:oss_surveys_api/oss_surveys_api.dart" as surveys_api;
import "package:oss_surveys_customer/database/dao/pages_dao.dart";
import "package:oss_surveys_customer/database/database.dart";
import "package:oss_surveys_customer/main.dart";
import "package:oss_surveys_customer/utils/html_controller.dart";
import "package:oss_surveys_customer/utils/offline_file_controller.dart";

/// Pages Controller class
///
/// This class contains methods for processing Survey Pages
/// e.g. offloading media, processing HTML, etc.
class PagesController {
  /// Persists [page] with reference to persited Survey by [surveyId]
  ///
  /// Offlines medias and processes HTML into displayable format and persists it
  Future<void> persistPage(
    surveys_api.DeviceSurveyPageData page,
    int surveyId,
  ) async {
    logger.info("Persisting page ${page.id}");
    Map<String, String> mediaFilesMap =
        await offlineMedias(page.properties?.toList() ?? []);
    String processedHTML = HTMLController.processSurveyPage(
      page,
      mediaFilesMap,
    );

    await pagesDao.createPage(PagesCompanion.insert(
      externalId: page.id!,
      html: processedHTML,
      pageNumber: page.pageNumber!,
      surveyId: surveyId,
    ));
  }

  /// Offline medias for a Page
  Future<Map<String, String>> offlineMedias(
    List<surveys_api.PageProperty> pageProperties,
  ) async {
    Map<String, String> mediaFilesMap = {};

    pageProperties.retainWhere(
        (element) => element.type == surveys_api.PagePropertyType.IMAGE_URL);

    for (var property in pageProperties) {
      logger.info("Offlining media ${property.value}");

      if (property.type == surveys_api.PagePropertyType.IMAGE_URL) {
        File? offlinedFile =
            await offlineFileController.getOfflineFile(property.value);

        if (offlinedFile == null) {
          logger.shout("Couldn't offline media ${property.value}");
          continue;
        }

        mediaFilesMap.putIfAbsent(property.key, () => offlinedFile.path);
      }
    }

    return mediaFilesMap;
  }
}

final pagesController = PagesController();
