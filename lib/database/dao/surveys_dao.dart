import "package:drift/drift.dart";
import "package:oss_surveys_customer/database/database.dart";
import "package:oss_surveys_customer/main.dart";
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

  /// Updates persisted Survey by [externalId] and [updatedSurvey]
  Future<Survey> updateSurveyByExternalId(
    String externalId,
    Survey updatedSurvey,
  ) async {
    Survey? foundSurvey = await findSurveyByExternalId(externalId);

    if (foundSurvey == null) {
      logger.shout("Couldn't find Survey with external id $externalId");
    }

    await update(surveys).replace(foundSurvey!.copyWith(
      title: updatedSurvey.title,
      timeout: updatedSurvey.timeout,
      publishStart: Value(updatedSurvey.publishStart),
      publishEnd: Value(updatedSurvey.publishEnd),
    ));

    return await (select(surveys)
          ..where((row) => row.id.equals(foundSurvey.id)))
        .getSingle();
  }

  /// Deletes persisted Survey by [id]
  Future deleteSurvey(int id) async {
    return (delete(surveys)..where((row) => row.id.equals(id)));
  }

  /// Finds currently active Survey
  Future<Survey?> findActiveSurvey() async {
    Survey? foundSurvey = await (select(surveys)
          ..where((row) =>
              row.publishStart.isSmallerOrEqualValue(DateTime.now()) &
              row.publishEnd.isBiggerOrEqualValue(DateTime.now())))
        .getSingleOrNull();

    foundSurvey ??=
        await (select(surveys)..limit(1, offset: 0)).getSingleOrNull();

    return foundSurvey;
  }
}

final surveysDao = SurveysDao(database);
