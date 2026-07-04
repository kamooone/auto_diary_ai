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

  Future<List<LocationLog>> getAll() {

    return isar.locationLogs
        .where()
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
        .findAll();
  }

  Future<LocationLog?> getLatest() {

    return isar.locationLogs
        .where()
        .sortByTimestampDesc()
        .findFirst();
  }

}