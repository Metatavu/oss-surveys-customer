import "package:drift/drift.dart";

/// Survey persistence model
class Survey extends Table {
  TextColumn get id => text().unique().withLength(min: 36, max: 36)();
  TextColumn get name => text()();
  TextColumn get creatorId => text().withLength(min: 36, max: 36)();
  TextColumn get lastModifierId => text().withLength(min: 36, max: 36)();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get modifiedAt => dateTime()();
  
  @override
  Set<Column> get primaryKey => { id };
}