import 'dart:convert';
import 'package:isar/isar.dart';
import '../../domain/entities/place_candidate.dart';
import '../models/place_search_cache.dart';
import 'place_candidate_cache.dart';

/// 施設の検索結果をIsarに保存し、アプリを再起動しても再利用する
class IsarPlaceCandidateCache implements PlaceCandidateCache {
  final Isar isar;

  IsarPlaceCandidateCache(this.isar);

  // 店舗の入れ替わりを反映するため、古い結果は取り直す
  static const _maxAge = Duration(days: 90);

  @override
  Future<List<PlaceCandidate>?> get(String key) async {
    final cache =
        await isar.placeSearchCaches.filter().keyEqualTo(key).findFirst();

    if (cache == null) return null;
    if (DateTime.now().difference(cache.fetchedAt) > _maxAge) return null;

    final candidates = jsonDecode(cache.candidatesJson) as List;

    return [
      for (final candidate in candidates)
        PlaceCandidate(
          name: candidate['name'] as String,
          category: candidate['category'] as String?,
          distanceMeters: (candidate['distanceMeters'] as num).toDouble(),
        ),
    ];
  }

  @override
  Future<void> put(String key, List<PlaceCandidate> candidates) async {
    final cache = PlaceSearchCache()
      ..key = key
      ..candidatesJson = jsonEncode([
        for (final candidate in candidates)
          {
            'name': candidate.name,
            'category': candidate.category,
            'distanceMeters': candidate.distanceMeters,
          },
      ])
      ..fetchedAt = DateTime.now();

    await isar.writeTxn(() async {
      // 同じ座標の結果がすでにある場合は上書きする
      final existing =
          await isar.placeSearchCaches.filter().keyEqualTo(key).findFirst();
      if (existing != null) {
        cache.id = existing.id;
      }

      await isar.placeSearchCaches.put(cache);
    });
  }
}
