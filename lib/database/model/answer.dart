import "package:drift/drift.dart";

/// Answer persistence model
@DataClassName("Answer")
class Answers extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get pageExternalId => text()();
  TextColumn get answer => text()();
  TextColumn get questionType => text()();
}
