import 'package:isar/isar.dart';

import '../models/location_log.dart';

class IsarLocationDataSource {

  final Isar isar;

  IsarLocationDataSource(
      this.isar,
      );

  Future<void> save(
      double latitude,
      double longitude,
      ) async {

    final log = LocationLog()
      ..latitude = latitude
      ..longitude = longitude
      ..timestamp = DateTime.now();

    await isar.writeTxn(() async {

      await isar.locationLogs.put(log);

    });
  }

  Future<void> saveAll(
      List<LocationLog> logs,
      ) async {
    await isar.writeTxn(() async {
      await isar.locationLogs.putAll(logs);
    });
  }

  Future<List<LocationLog>> getAll() {

    // 滞在の到着・出発など、後から届く位置もあるため時刻順に並べる
    return isar.locationLogs
        .where()
        .sortByTimestamp()
        .findAll();
  }

  Future<List<LocationLog>> getByDate(
      DateTime date,
      ) {

    final start =
    DateTime(date.year, date.month, date.day);

    final end =
    start.add(const Duration(days: 1));

    return isar.locationLogs
        .filter()
        .timestampBetween(start, end)
        .sortByTimestamp()
        .findAll();
  }

  Future<LocationLog?> getEarliest() {
    return isar.locationLogs
        .where()
        .sortByTimestamp()
        .findFirst();
  }

  Future<LocationLog?> getLatest() {

    return isar.locationLogs
        .where()
        .sortByTimestampDesc()
        .findFirst();
  }

}