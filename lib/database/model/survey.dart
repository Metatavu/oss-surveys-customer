import "package:drift/drift.dart";

/// Survey persistence model
@DataClassName("Survey")
class Surveys extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get externalId => text().unique().withLength(min: 36, max: 36)();
  TextColumn get title => text()();
  TextColumn get creatorId => text().withLength(min: 36, max: 36)();
  TextColumn get lastModifierId => text().withLength(min: 36, max: 36)();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get modifiedAt => dateTime()();
}
