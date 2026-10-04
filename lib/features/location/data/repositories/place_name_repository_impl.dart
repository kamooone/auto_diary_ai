import 'package:flutter/widgets.dart';
import 'package:geocoding/geocoding.dart' as geocoding;
import '../../domain/repositories/place_name_repository.dart';

class PlaceNameRepositoryImpl implements PlaceNameRepository {
  static const _locale = Locale('ja', 'JP');

  final _geocoding = geocoding.Geocoding();

  // 同じ場所を何度も問い合わせないよう、結果を保持する
  final _cache = <String, String>{};

  @override
  Future<String?> getPlaceName(double latitude, double longitude) async {
    // 小数第4位(約10m)で丸めた座標をキーにする
    final key = '${latitude.toStringAsFixed(4)},${longitude.toStringAsFixed(4)}';

    final cached = _cache[key];
    if (cached != null) return cached;

    try {
      final placemarks = await _geocoding.placemarkFromCoordinates(
        latitude,
        longitude,
        locale: _locale,
      );
      if (placemarks.isEmpty) return null;

      final name = _format(placemarks.first);
      if (name == null) return null;

      _cache[key] = name;
      return name;
    } catch (e) {
      debugPrint('地名の取得に失敗しました: $e');
      return null;
    }
  }

  // 「都道府県 + 市区町村 + 町名」の形にまとめる
  String? _format(geocoding.Placemark placemark) {
    final parts = <String>[];

    for (final part in [
      placemark.administrativeArea,
      placemark.locality,
      placemark.subLocality,
      placemark.thoroughfare,
    ]) {
      if (part != null && part.isNotEmpty && !parts.contains(part)) {
        parts.add(part);
      }
    }

    if (parts.isEmpty) {
      final name = placemark.name;
      return (name == null || name.isEmpty) ? null : name;
    }

    return parts.join();
  }
}
