import "dart:io";
import "package:drift/drift.dart";
import "package:drift/native.dart";
import "package:oss_surveys_customer/database/model/key.dart";
import "package:oss_surveys_customer/database/model/answer.dart";
import "package:oss_surveys_customer/database/model/survey.dart";
import "package:oss_surveys_customer/database/model/page.dart";
import "package:path_provider/path_provider.dart";
import "package:path/path.dart" as p;

part "database.g.dart";

/// Database class
///
/// Opens an in-file database, creating it if it doesn't exist.
/// Add new migrations to [migration.onUpgrade] and bump the [schemaVersion].
@DriftDatabase(tables: [
  Surveys,
  Keys,
  Pages,
  Answers,
])
class Database extends _$Database {
  Database({NativeDatabase? database}) : super(_openConnection());
  Database.fromQueryExecutor([QueryExecutor? e])
      : super(e ?? _openConnection());

  @override
  int get schemaVersion => 7;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(onCreate: (Migrator migrator) async {
      await migrator.createAll();
    }, beforeOpen: (OpeningDetails details) async {
      // According to documentation, SQLite3 has foreign keys need to be explicitly enabled
      // https://drift.simonbinder.eu/docs/getting-started/advanced_dart_tables/#references
      await customStatement("PRAGMA foreign_keys = ON");
    }, onUpgrade: (Migrator migrator, int from, int to) async {
      for (int target = from + 1; target <= to; target++) {
        switch (target) {
          case 1:
            return await migrator.create(surveys);
          case 2:
            return await migrator.create(keys);
          case 3:
            {
              await migrator.drop(surveys);
              await migrator.create(surveys);
              await migrator.create(pages);
              await migrator.alterTable(TableMigration(pages));

              return;
            }
          case 4:
            {
              await migrator.drop(surveys);
              await migrator.drop(pages);
              await migrator.create(surveys);
              await migrator.create(pages);
              await migrator.alterTable(TableMigration(pages));

              return;
            }
          case 5:
            {
              await migrator.drop(pages);
              await migrator.create(pages);
              await migrator.alterTable(TableMigration(pages));
              await migrator.create(answers);
              await migrator.alterTable(TableMigration(answers));
            }
          case 6:
            {
              // Ignore this migration
            }
          case 7:
            {
              await migrator.addColumn(answers, answers.timestamp);
            }
        }
      }
    });
  }
}

/// Opens connection
QueryExecutor _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, "db.sqlite"));

    return NativeDatabase.createInBackground(file);
  });
}

final database = Database();
