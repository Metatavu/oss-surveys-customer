import "package:drift/drift.dart";

/// Survey persistence model
@DataClassName("Survey")
class Surveys extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get externalId => text().unique().withLength(min: 36, max: 36)();
  TextColumn get title => text()();
  DateTimeColumn get publishStart => dateTime().nullable()();
  DateTimeColumn get publishEnd => dateTime().nullable()();
  IntColumn get timeout => integer()();
  DateTimeColumn get modifiedAt => dateTime()();
}
