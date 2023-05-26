import "package:drift/drift.dart";
import "package:oss_surveys_customer/database/database.dart";
import "../model/survey.dart";
import "package:oss_surveys_api/oss_surveys_api.dart" as surveys_api;

part "surveys_dao.g.dart";

/// Surveys DAO
@DriftAccessor(tables: [Surveys], include: {"tables.drift"})
class SurveysDao extends DatabaseAccessor<Database> with _$SurveysDaoMixin {
  SurveysDao(Database database) : super(database);

  /// Creates and persists new Survey from REST [newSurvey]
  Future<Survey> createSurvey(SurveysCompanion newSurvey) async {
    int createdSurveyId = await into(surveys).insert(newSurvey);

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
  Future deleteSurvey(int id) async {
    return await (delete(surveys)..where((row) => row.id.equals(id))).go();
  }

  /// Finds currently active Survey
  Future<Survey?> findActiveSurvey() async {
    Survey? foundSurvey = await (select(surveys)
          ..where(
            (row) =>
                row.publishStart.isSmallerOrEqualValue(DateTime.now()) &
                row.publishEnd.isBiggerOrEqualValue(DateTime.now()),
          )
          ..limit(1))
        .getSingleOrNull();

    foundSurvey ??= await (select(surveys)
          ..where((row) => row.publishStart.isNull() & row.publishEnd.isNull())
          ..limit(1))
        .getSingleOrNull();

    return foundSurvey;
  }

  /// Updates [survey]
  Future<Survey> updateSurvey(
      Survey existingSurvey, surveys_api.DeviceSurveyData newSurvey) async {
    await update(surveys).replace(
      existingSurvey.copyWith(
        title: newSurvey.title,
        timeout: newSurvey.timeout,
        publishStart: Value(newSurvey.publishStartTime),
        publishEnd: Value(newSurvey.publishEndTime),
        modifiedAt: newSurvey.metadata!.modifiedAt!,
      ),
    );

    return await (select(surveys)
          ..where((row) => row.id.equals(existingSurvey.id)))
        .getSingle();
  }
}

final surveysDao = SurveysDao(database);
