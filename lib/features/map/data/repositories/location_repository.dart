import 'package:isar/isar.dart';
import '../models/location_log.dart';

class LocationRepository {

  final Isar isar;

  LocationRepository(this.isar);

  Future<void> saveLocation(double lat, double lng) async {

    final log = LocationLog()
      ..latitude = lat
      ..longitude = lng
      ..timestamp = DateTime.now();

    await isar.writeTxn(() async {
      await isar.locationLogs.put(log);
    });

  }

  // 全取得
  Future<List<LocationLog>> getLocations() async {
    return await isar.locationLogs.where().findAll();
  }

  // 最新1件取得（デバッグ用）
  Future<LocationLog?> getLatestLocation() async {
    final results = await isar.locationLogs
        .where()
        .sortByTimestampDesc()
        .findFirst();

    return results;
  }
}