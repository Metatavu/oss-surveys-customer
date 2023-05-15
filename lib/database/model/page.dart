import "package:drift/drift.dart";
import "package:oss_surveys_customer/database/model/survey.dart";

/// Page persistence model
@DataClassName("Page")
class Pages extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get externalId => text()();
  TextColumn get html => text()();
  IntColumn get pageNumber => integer()();
  IntColumn get surveyId => integer().references(Surveys, #id)();
}
