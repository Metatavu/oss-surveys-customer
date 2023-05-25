import "package:drift/drift.dart";
import "package:oss_surveys_customer/database/model/page.dart";

/// Answer persistence model
@DataClassName("Answer")
class Answers extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get pageId => integer().references(Pages, #id)();
  TextColumn get pageExternalId => text()();
  TextColumn get answer => text()();
  TextColumn get questionType => text()();
}
