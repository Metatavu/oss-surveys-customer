import "package:drift/drift.dart";

/// Key persistence model
@DataClassName("Key")
class Keys extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get key => text().unique()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}