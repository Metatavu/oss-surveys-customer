import 'package:drift/drift.dart';

/// Page persistence model
@DataClassName("Page")
class Pages extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get externalId => text()();
  TextColumn get html => text()();
}
