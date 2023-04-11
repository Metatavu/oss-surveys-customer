import "dart:io";
import "package:drift/drift.dart";
import "package:drift/native.dart";
import "package:oss_surveys_customer/database/model/key.dart";
import "package:oss_surveys_customer/database/model/survey.dart";
import "package:path_provider/path_provider.dart";
import "package:path/path.dart" as p;

part "database.g.dart";

/// Database class
/// 
/// Opens an in-file database, creating it if it doesn't exist.
/// Add new migrations to [migration.onUpgrade] and bump the [schemaVersion].
@DriftDatabase(tables: [Surveys, Keys], include: {"tables.drift"})
class Database extends _$Database {  
  Database(): super(_openConnection());
  
  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator migrator) async {
        await migrator.createAll();
      },
      onUpgrade: (Migrator migrator, int from, int to) async {
        for (int target = from + 1; target <= to; target++) {
          switch (target) {
            case 1: return await migrator.create(surveys);
            case 2: return await migrator.create(keys);
          }
        }
      }
    );
  }
  
  /// Checks if this device is approved e.g. it has received a key from the API.
  Future<bool> isDeviceApproved() async {
    return (select(keys).getSingleOrNull()).then((value) => value != null);
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
