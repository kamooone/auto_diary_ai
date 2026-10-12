import 'dart:math';
import '../entities/registered_place.dart';
import '../entities/timeline_item.dart';

/// 滞在が、ユーザーが登録した場所にあたるかを調べる
class RegisteredPlaceFinder {
  // 滞在の位置からこの距離以内に登録した場所があれば、同じ場所とみなす
  static const radiusMeters = 50.0;

  /// 滞在と同じ場所とみなせる、最も近い登録済みの場所(なければnull)
  RegisteredPlace? find(Stay stay, List<RegisteredPlace> places) {
    RegisteredPlace? nearest;
    var nearestDistance = radiusMeters;

    for (final place in places) {
      final distance = _distance(
        stay.latitude,
        stay.longitude,
        place.latitude,
        place.longitude,
      );

      if (distance <= nearestDistance) {
        nearest = place;
        nearestDistance = distance;
      }
    }

    return nearest;
  }

  // 2点間の距離(m)
  double _distance(double lat1, double lng1, double lat2, double lng2) {
    const earthRadius = 6371000.0;
    const toRadians = pi / 180;

    final dLat = (lat2 - lat1) * toRadians;
    final dLng = (lng2 - lng1) * toRadians;

    final h = sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1 * toRadians) *
            cos(lat2 * toRadians) *
            sin(dLng / 2) *
            sin(dLng / 2);

    return 2 * earthRadius * asin(min(1.0, sqrt(h)));
  }
}
