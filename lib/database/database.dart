import "dart:io";
import "package:drift/drift.dart";
import "package:drift/native.dart";
import "package:oss_surveys_api/oss_surveys_api.dart";
import "package:path_provider/path_provider.dart";
import "package:path/path.dart" as p;

part "database.g.dart";

/// Database class
/// 
/// Opens an in-file database, creating it if it doesn't exist.
/// Add new migrations to [migration.onUpgrade] and bump the [schemaVersion].
@DriftDatabase(tables: [Survey])
class Database extends _$Database {
  
  Database(): super(_openConnection());
  
  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator migrator) async {
        await migrator.createAll();
      },
      onUpgrade: (Migrator migrator, int from, int to) async {
        if (from == 0 && to == 1) {
          await migrator.createTable(survey)
        }
      }
    );
  }
}

/// Opens connection
LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, "db.sqlite"));
    
    return NativeDatabase(file);
  });
}

final database = Database();
