import 'dart:async';
import 'package:geolocator/geolocator.dart';
import '../../domain/entities/location.dart';
import '../../domain/repositories/location_repository.dart';
import '../datasources/gps_location_datasource.dart';
import '../datasources/isar_location_datasource.dart';

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

    await for (final position in gps.getPositionStream()) {

      await local.save(
        position.latitude,
        position.longitude,
      );

      yield Location(
        id: 0,
        latitude: position.latitude,
        longitude: position.longitude,
        timestamp: position.timestamp ?? DateTime.now(),
      );
    }
  }

  @override
  Future<List<Location>> getLocations() async {

    final logs =
    await local.getAll();

    return logs.map((e) {

      return Location(
        id: e.id,
        latitude: e.latitude,
        longitude: e.longitude,
        timestamp: e.timestamp,
      );

    }).toList();

  }

  @override
  Future<List<Location>> getLocationsByDate(
      DateTime date,
      ) async {

    final logs =
    await local.getByDate(date);

    return logs.map((e) {

      return Location(
        id: e.id,
        latitude: e.latitude,
        longitude: e.longitude,
        timestamp: e.timestamp,
      );

    }).toList();

  }

  @override
  Future<Location?> getLatestLocation() async {

    final log =
    await local.getLatest();

    if (log == null) {
      return null;
    }

    return Location(
      id: log.id,
      latitude: log.latitude,
      longitude: log.longitude,
      timestamp: log.timestamp,
    );

  }
}