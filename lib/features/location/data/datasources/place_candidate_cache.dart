import '../../domain/entities/place_candidate.dart';

/// 施設の検索結果の保存先
abstract class PlaceCandidateCache {
  /// 保存済みの検索結果を取得(保存されていない場合はnull)
  Future<List<PlaceCandidate>?> get(String key);

  Future<void> put(String key, List<PlaceCandidate> candidates);
}

/// アプリ起動中だけ保持する
class MemoryPlaceCandidateCache implements PlaceCandidateCache {
  final _entries = <String, List<PlaceCandidate>>{};

  @override
  Future<List<PlaceCandidate>?> get(String key) async => _entries[key];

  @override
  Future<void> put(String key, List<PlaceCandidate> candidates) async {
    _entries[key] = candidates;
  }
}
