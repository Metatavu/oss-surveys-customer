import "package:drift/drift.dart";

/// Key persistence model
@DataClassName("Key")
class Keys extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get key => text().nullable()();
  TextColumn get deviceId => text().unique()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}
