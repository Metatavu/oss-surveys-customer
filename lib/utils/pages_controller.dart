import "dart:io";
import "package:oss_surveys_api/oss_surveys_api.dart" as surveys_api;
import "package:oss_surveys_customer/database/dao/pages_dao.dart";
import "package:oss_surveys_customer/database/database.dart" as database;
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
    database.Page? existingPage = await pagesDao.findPageByExternalId(page.id!);
    Map<String, String> mediaFilesMap =
        await _offlineMedias(page.properties?.toList() ?? []);
    String processedHTML = HTMLController.processSurveyPage(
      page,
      mediaFilesMap,
    );
    if (existingPage == null) {
      logger.info("Persisting new page ${page.id}");
      await pagesDao.createPage(
        database.PagesCompanion.insert(
          externalId: page.id!,
          html: processedHTML,
          pageNumber: page.pageNumber!,
          surveyId: surveyId,
          modifiedAt: page.metadata!.modifiedAt!,
        ),
      );
    } else {
      logger.info(
        "Page with id ${page.id} already exists, checking if updated...",
      );
      if (_comparePages(existingPage, page)) {
        logger.info("Page with id ${page.id} is updated, updating...");
        await pagesDao.updatePage(
          existingPage,
          database.PagesCompanion.insert(
              externalId: page.id!,
              html: processedHTML,
              pageNumber: page.pageNumber!,
              surveyId: surveyId,
              modifiedAt: page.metadata!.modifiedAt!),
        );
      }
    }
  }

  /// Deletes Pages by [surveyId]
  Future deletePagesBySurveyId(int surveyId) async {
    List<database.Page> pages = await pagesDao.listPagesBySurveyId(surveyId);

    for (var page in pages) {
      await pagesDao.deletePage(page.id);
    }
  }

  /// Offline medias for a Page
  Future<Map<String, String>> _offlineMedias(
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

  /// Compares if [page] is different from persisted Page
  bool _comparePages(
          database.Page page, surveys_api.DeviceSurveyPageData newPage) =>
      page.modifiedAt.isBefore(newPage.metadata!.modifiedAt!);
}

final pagesController = PagesController();
