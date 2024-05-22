import "dart:io";
import "package:drift/drift.dart";
import "package:list_ext/list_ext.dart";
import "package:oss_surveys_api/oss_surveys_api.dart" as surveys_api;
import "package:oss_surveys_customer/database/dao/pages_dao.dart";
import "package:oss_surveys_customer/database/database.dart" as database;
import "package:oss_surveys_customer/main.dart";
import "package:oss_surveys_customer/utils/html_controller.dart";
import "package:oss_surveys_customer/utils/offline_file_controller.dart";
import "package:simple_logger/simple_logger.dart";

/// Pages Controller class
///
/// This class contains methods for processing Survey Pages
/// e.g. offloading media, processing HTML, etc.
class PagesController {
  /// Persists [page] with reference to persisted Survey by [surveyId]
  ///
  /// Offlines medias and processes HTML into displayable format and persists it
  Future<void> persistPage(
    surveys_api.DeviceSurveyPageData page,
    int surveyId,
  ) async {
    database.Page? existingPage = await pagesDao.findPageByExternalId(page.id!);
    Map<String, String> mediaFilesMap = await _offlineMedias(
      page.properties?.toList() ?? [],
      page.layoutVariables?.toList() ?? [],
    );
    String processedHTML = HTMLController.processSurveyPage(
      page,
      mediaFilesMap,
    );
    if (existingPage == null) {
      SimpleLogger().info("Persisting new page ${page.id}");
      await pagesDao.createPage(
        database.PagesCompanion.insert(
          externalId: page.id!,
          html: processedHTML,
          pageNumber: page.pageNumber!,
          surveyId: surveyId,
          questionType: Value(page.question?.type.name),
          modifiedAt: DateTime.parse(page.metadata!.modifiedAt!),
        ),
      );
    } else {
      if (_comparePages(existingPage, page)) {
        SimpleLogger().info("Page with id ${page.id} is updated, updating...");
        await pagesDao.updatePage(
          existingPage,
          database.PagesCompanion.insert(
            externalId: page.id!,
            html: processedHTML,
            pageNumber: page.pageNumber!,
            surveyId: surveyId,
            questionType: Value(page.question?.type.name),
            modifiedAt: DateTime.parse(page.metadata!.modifiedAt!),
          ),
        );
      }
    }
  }

  /// Deletes Pages by [surveyId]
  Future<void> deletePagesBySurveyId(int surveyId) async {
    List<database.Page> pages = await pagesDao.listPagesBySurveyId(surveyId);

    for (var page in pages) {
      await pagesDao.deletePage(page.id);
    }
  }

  /// Offline medias for a Page
  Future<Map<String, String>> _offlineMedias(
    List<surveys_api.PageProperty> pageProperties,
    List<surveys_api.LayoutVariable> layoutVariables,
  ) async {
    String imageBaseUrl = configuration.getImageBaseUrl();
    Map<String, String> mediaFilesMap = {};
    layoutVariables.retainWhere((variable) =>
        variable.type == surveys_api.LayoutVariableType.IMAGE_URL);
    pageProperties.retainWhere((property) =>
        layoutVariables
            .firstWhereOrNull((variable) => variable.key == property.key) !=
        null);

    for (var property in pageProperties) {
      if (property.value.isEmpty) {
        continue;
      }

      File? offlinedFile = await offlineFileController
          .getOfflineFile(imageBaseUrl + property.value);

      if (offlinedFile == null) {
        SimpleLogger().shout("Couldn't offline media ${property.value}");
        continue;
      }

      mediaFilesMap[property.key] = offlinedFile.absolute.path;
    }

    return mediaFilesMap;
  }

  /// Compares if [page] is different from persisted Page
  bool _comparePages(
          database.Page page, surveys_api.DeviceSurveyPageData newPage) =>
      page.modifiedAt.isBefore(DateTime.parse(newPage.metadata!.modifiedAt!));
}

final pagesController = PagesController();
