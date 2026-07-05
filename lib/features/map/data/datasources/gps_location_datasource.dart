import 'package:flutter/cupertino.dart';
import 'package:geolocator/geolocator.dart';

import '../../../../common/constants/map_constants.dart';

class GpsLocationDataSource {

  Future<bool> requestPermission() async {

    final enabled =
    await Geolocator.isLocationServiceEnabled();

    if (!enabled) {
      return false;
    }

    var permission =
    await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission =
      await Geolocator.requestPermission();
    }

    return permission !=
        LocationPermission.deniedForever;
  }

  Stream<Position> getPositionStream() {
    return Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: MapConstants.locationDistanceFilterMeters,
      ),
    ).where((position) {
      final ok =
          position.latitude.isFinite &&
              position.longitude.isFinite;

      if (!ok) {
        debugPrint(
          "破棄: ${position.latitude}, ${position.longitude}",
        );
      }

      return ok;
    });
  }

}