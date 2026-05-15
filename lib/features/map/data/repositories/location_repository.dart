import 'dart:developer' as developer;
import 'package:isar/isar.dart';
import 'package:auto_diary_ai/features/map/data/models/location_log.dart';

class LocationRepository {

  final Isar isar;

  LocationRepository(this.isar);

  // 位置保存
  Future<void> saveLocation(double lat, double lng) async {

    final log = LocationLog()
      ..latitude = lat
      ..longitude = lng
      ..timestamp = DateTime.now();

    await isar.writeTxn(() async {
      await isar.locationLogs.put(log);
    });

    await _printLogs();
  }

  // 全取得
  Future<List<LocationLog>> getLocations() async {

    final logs = await isar.locationLogs.where().findAll();

    await _printLogs();

    return logs;
  }

  // 最新1件取得（デバッグ用）
  Future<LocationLog?> getLatestLocation() async {

    final result = await isar.locationLogs
        .where()
        .sortByTimestampDesc()
        .findFirst();

    await _printLogs();

    return result;
  }

  // ログ表示用関数
  Future<void> _printLogs() async {

    final logs = await isar.locationLogs.where().findAll();

    developer.log("===== LocationLogs =====");

    for (final log in logs) {
      developer.log(
        "ID:${log.id}  "
            "Lat:${log.latitude}  "
            "Lng:${log.longitude}  "
            "Time:${log.timestamp}",
      );
    }

    developer.log("========================");
  }
}