import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:auto_diary_ai/common/constants/map_constants.dart';

class LocationService {

  StreamSubscription<Position>? _positionStream;

  final StreamController<Position> _locationController =
  StreamController.broadcast();

  Stream<Position> get locationStream => _locationController.stream;

  Future<void> start() async {

    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.deniedForever) return;

    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: MapConstants.locationDistanceFilterMeters,
    );

    _positionStream = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen((Position position) {

      _locationController.add(position);

    });
  }

  void dispose() {
    _positionStream?.cancel();
    _locationController.close();
  }
}