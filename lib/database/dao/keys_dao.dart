import "package:drift/drift.dart";
import "package:oss_surveys_customer/database/database.dart";
import "../model/key.dart";

part "keys_dao.g.dart";

/// Keys DAO
@DriftAccessor(tables: [Keys], include: {"tables.drift"})
class KeysDao extends DatabaseAccessor<Database> with _$KeysDaoMixin {
  KeysDao(Database database) : super(database);

  /// Checks if this device is approved e.g. it has received a key from the API.
  Future<bool> isDeviceApproved() async {
    return (select(keys).getSingleOrNull())
        .then((value) => value != null && value.key != null);
  }

  /// Persists given [deviceId] to database
  Future<int> persistDeviceId(String deviceId) async {
    return await into(keys).insert(KeysCompanion.insert(deviceId: deviceId));
  }

  /// Persists given [deviceKey] to database
  Future<int> persistDeviceKey(String deviceKey) async {
    int rowId = (await select(keys).getSingle()).id;
    return (update(keys)..where((row) => row.id.equals(rowId)))
        .write(KeysCompanion(key: Value(deviceKey)));
  }

  /// Returns this devices id
  Future<String?> getDeviceId() async {
    return (select(keys).getSingleOrNull().then((value) => value?.deviceId));
  }

  /// Returns this devices key
  Future<String?> getDeviceKey() async {
    return (select(keys).getSingleOrNull().then((value) => value?.key));
  }
}

final keysDao = KeysDao(database);
