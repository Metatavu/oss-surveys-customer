import "package:drift/drift.dart";
import "package:list_ext/list_ext.dart";
import "package:oss_surveys_customer/database/database.dart";
import "../model/survey.dart";
import "package:oss_surveys_api/oss_surveys_api.dart" as surveys_api;

part "surveys_dao.g.dart";

/// Surveys DAO
@DriftAccessor(tables: [Surveys])
class SurveysDao extends DatabaseAccessor<Database> with _$SurveysDaoMixin {
  SurveysDao(Database database) : super(database);

  /// Creates and persists new Survey from REST [newSurvey]
  Future<Survey> createSurvey({
    required String externalId,
    required String title,
    required int timeout,
    required DateTime modifiedAt,
    DateTime? publishStart,
    DateTime? publishEnd,
  }) async {
    int createdSurveyId = await into(surveys).insert(
      SurveysCompanion.insert(
        externalId: externalId,
        title: title,
        publishStart: Value(publishStart),
        publishEnd: Value(publishEnd),
        timeout: timeout,
        modifiedAt: modifiedAt,
      ),
    );

    return await (select(surveys)
          ..where((row) => row.id.equals(createdSurveyId)))
        .getSingle();
  }

  /// Finds persisted Survey by [externalId]
  Future<Survey?> findSurveyByExternalId(String externalId) async {
    return await (select(surveys)
          ..where((row) => row.externalId.equals(externalId)))
        .getSingleOrNull();
  }

  /// Lists all persisted Surveys
  Future<List<Survey>> listSurveys() async {
    return await (select(surveys).get());
  }

  /// Deletes persisted Survey by [id]
  Future<int> deleteSurvey(int id) async {
    return await (delete(surveys)..where((row) => row.id.equals(id))).go();
  }

  /// Finds currently active Survey
  Future<Survey?> findActiveSurvey() async {
    final now = DateTime.now();
    List<Survey> foundSurveys = await (select(surveys)
          ..where(
            (row) =>
                (row.publishStart.isNull() |
                    row.publishStart.isSmallerOrEqualValue(now)) &
                (row.publishEnd.isBiggerOrEqualValue(now) |
                    row.publishEnd.isNull()),
          )
          ..orderBy([(row) => OrderingTerm.desc(row.publishStart)]))
        .get();

    return foundSurveys.firstWhereOrNull(
      (element) =>
          element.publishStart?.isBefore(
            now,
          ) ??
          true,
    );
  }

  /// Updates [survey]
  Future<Survey> updateSurvey(
      Survey existingSurvey, surveys_api.DeviceSurveyData newSurvey) async {
    final publishStartTime = newSurvey.publishStartTime;
    final publishEndTime = newSurvey.publishEndTime;
    final modifiedAt = newSurvey.metadata!.modifiedAt!;

    await update(surveys).replace(
      existingSurvey.copyWith(
        title: newSurvey.title,
        timeout: newSurvey.timeout,
        publishStart: publishStartTime != null
            ? Value(DateTime.parse(publishStartTime))
            : const Value.absent(),
        publishEnd: publishEndTime != null
            ? Value(DateTime.parse(publishEndTime))
            : const Value.absent(),
        modifiedAt: DateTime.parse(modifiedAt),
      ),
    );

    return await (select(surveys)
          ..where((row) => row.id.equals(existingSurvey.id)))
        .getSingle();
  }
}

final surveysDao = SurveysDao(database);
