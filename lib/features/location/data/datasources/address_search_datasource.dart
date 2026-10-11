import 'package:flutter/widgets.dart';
import 'package:geocoding/geocoding.dart' as geocoding;
import '../../domain/repositories/place_search_repository.dart';

/// 地名や住所から座標を調べる(動作確認用)
class AddressSearchDataSource {
  static const _locale = Locale('ja', 'JP');

  final _geocoding = geocoding.Geocoding();

  /// [address]の座標(見つからない場合はnull)
  Future<Coordinate?> findCoordinate(String address) async {
    final locations = await _geocoding.locationFromAddress(
      address,
      locale: _locale,
    );
    if (locations.isEmpty) return null;

    return (
      latitude: locations.first.latitude,
      longitude: locations.first.longitude,
    );
  }
}
