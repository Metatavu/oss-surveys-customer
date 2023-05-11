import "package:drift/drift.dart";
import "package:oss_surveys_customer/database/database.dart";
import "../model/page.dart";

part "pages_dao.g.dart";

/// Pages DAO
@DriftAccessor(tables: [Pages], include: {"tables.drift"})
class PagesDao extends DatabaseAccessor<Database> with _$PagesDaoMixin {
  PagesDao(Database database) : super(database);

  /// Persists [page]
  Future<Page> createPage(PagesCompanion newPage) async {
    int createdPageId = await into(pages).insert(newPage);

    return await (select(pages)..where((row) => row.id.equals(createdPageId)))
        .getSingle();
  }

  /// Lists all Pages by [surveyId]
  Future<List<Page>> listPagesBySurveyId(int surveyId) async {
    return await (select(pages)..where((row) => row.surveyId.equals(surveyId)))
        .get();
  }

  /// Finds Page by [externalId]
  Future<Page?> findPageByExternalId(String externalId) async {
    return await (select(pages)
          ..where((row) => row.externalId.equals(externalId)))
        .getSingleOrNull();
  }

  /// Deletes Page by [id]
  Future deletePage(int id) async {
    return (delete(pages)..where((row) => row.id.equals(id)));
  }
}

final pagesDao = PagesDao(database);
