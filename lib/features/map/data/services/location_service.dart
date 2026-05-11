import 'dart:async';
import 'dart:developer' as developer;
import 'package:geolocator/geolocator.dart';
import 'package:auto_diary_ai/common/constants/map_constants.dart';
import 'package:auto_diary_ai/features/map/data/repositories/location_repository.dart';

class LocationService {

  final LocationRepository repository;
  LocationService(this.repository);

  StreamSubscription<Position>? _positionStream;

  final StreamController<Position> _locationController =
  StreamController.broadcast();

  Stream<Position> get locationStream => _locationController.stream;

  Future<void> loadLocations() async {

    final logs = await repository.getLocations();

    developer.log(
      "DB records: ${logs.length}",
      name: "LocationService",
    );

    for (final log in logs) {
      developer.log(
        "DB: ${log.latitude}, ${log.longitude}, ${log.timestamp}",
        name: "LocationService",
      );
    }

  }

  Future<void> start() async {

    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      developer.log("Location service disabled");
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.deniedForever) {
      developer.log("Location permission denied forever");
      return;
    }

    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: MapConstants.locationDistanceFilterMeters,
    );

    // 現在地取得
    _positionStream = Geolocator
        .getPositionStream(locationSettings: locationSettings)
        // リアルタイム現在地取得
        .listen((position) async {
          developer.log(
            "Location received: ${position.latitude}, ${position.longitude}",
            name: "LocationService",
          );

          _locationController.add(position);

          // 保存
          await repository.saveLocation(
            position.latitude,
            position.longitude,
          );
        });
  }

  void dispose() {
    _positionStream?.cancel();
    _locationController.close();
  }
}