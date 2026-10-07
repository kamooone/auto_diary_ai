import 'dart:async';
import '../../domain/entities/location.dart';
import '../../domain/repositories/location_repository.dart';
import '../datasources/gps_location_datasource.dart';
import '../datasources/isar_location_datasource.dart';
import '../models/location_log.dart';
import '../services/background_location_service.dart';

class LocationRepositoryImpl
    implements LocationRepository {

  final GpsLocationDataSource gps;

  final IsarLocationDataSource local;

  LocationRepositoryImpl({
    required this.gps,
    required this.local,
  });

  @override
  Stream<Location> startTracking() async* {

    final granted = await gps.requestPermission();

    if (!granted) {
      return;
    }

    // 保存は記録サービスが行う(起動時に未許可だった場合はここで開始する)
    await startLocationRecording(
      gps: gps,
      local: local,
    );

    await for (final position in gps.getPositionStream()) {

      yield Location(
        id: 0,
        latitude: position.latitude,
        longitude: position.longitude,
        timestamp: position.timestamp,
      );
    }
  }

  @override
  Future<List<Location>> getLocations() async {

    // iOSのネイティブ側が記録した位置情報を先に取り込む
    await importRecordedLocations(local);

    final logs =
    await local.getAll();

    return logs.map(_toEntity).toList();

  }

  @override
  Future<List<Location>> getLocationsByDate(DateTime date,) async {

    // iOSのネイティブ側が記録した位置情報を先に取り込む
    await importRecordedLocations(local);

    final logs =
    await local.getByDate(date);

    return logs.map(_toEntity).toList();

  }

  @override
  Future<Location?> getLatestLocation() async {

    // iOSのネイティブ側が記録した位置情報を先に取り込む
    await importRecordedLocations(local);

    final log =
    await local.getLatest();

    if (log == null) {
      return null;
    }

    return _toEntity(log);

  }

  @override
  Future<Location?> getLastLocationBefore(DateTime time) async {
    // iOSのネイティブ側が記録した位置情報を先に取り込む
    await importRecordedLocations(local);

    final log = await local.getLastBefore(time);
    return log == null ? null : _toEntity(log);
  }

  @override
  Future<Location?> getFirstLocationFrom(DateTime time) async {
    await importRecordedLocations(local);

    final log = await local.getFirstFrom(time);
    return log == null ? null : _toEntity(log);
  }

  Location _toEntity(LocationLog log) {
    return Location(
      id: log.id,
      latitude: log.latitude,
      longitude: log.longitude,
      timestamp: log.timestamp,
    );
  }
}