import 'package:flutter/widgets.dart';
import 'package:geocoding/geocoding.dart' as geocoding;
import 'package:isar/isar.dart';
import '../../domain/repositories/place_name_repository.dart';
import '../models/place_name_cache.dart';

class PlaceNameRepositoryImpl implements PlaceNameRepository {
  final Isar isar;

  PlaceNameRepositoryImpl(this.isar);

  static const _locale = Locale('ja', 'JP');

  // 地名の変更を反映するため、古い結果は取り直す
  static const _maxAge = Duration(days: 180);

  final _geocoding = geocoding.Geocoding();

  // アプリ起動中は、端末への問い合わせも省く
  final _memory = <String, String>{};

  @override
  Future<String?> getPlaceName(double latitude, double longitude) async {
    // 小数第4位(約10m)で丸めた座標をキーにする
    final key = '${latitude.toStringAsFixed(4)},${longitude.toStringAsFixed(4)}';

    final inMemory = _memory[key];
    if (inMemory != null) return inMemory;

    // 一度取得した場所は、端末に保存した結果を使う
    final saved = await _load(key);
    if (saved != null) {
      _memory[key] = saved;
      return saved;
    }

    try {
      final placemarks = await _geocoding.placemarkFromCoordinates(
        latitude,
        longitude,
        locale: _locale,
      );
      if (placemarks.isEmpty) return null;

      final name = _format(placemarks.first);
      if (name == null) return null;

      _memory[key] = name;
      await _save(key, name);
      return name;
    } catch (e) {
      debugPrint('地名の取得に失敗しました: $e');
      return null;
    }
  }

  Future<String?> _load(String key) async {
    final cache =
        await isar.placeNameCaches.filter().keyEqualTo(key).findFirst();

    if (cache == null) return null;
    if (DateTime.now().difference(cache.fetchedAt) > _maxAge) return null;

    return cache.name;
  }

  Future<void> _save(String key, String name) async {
    final cache = PlaceNameCache()
      ..key = key
      ..name = name
      ..fetchedAt = DateTime.now();

    await isar.writeTxn(() async {
      // 同じ座標の結果がすでにある場合は上書きする
      final existing =
          await isar.placeNameCaches.filter().keyEqualTo(key).findFirst();
      if (existing != null) {
        cache.id = existing.id;
      }

      await isar.placeNameCaches.put(cache);
    });
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
