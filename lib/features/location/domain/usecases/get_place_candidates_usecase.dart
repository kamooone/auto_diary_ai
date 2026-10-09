import '../entities/place_candidate.dart';
import '../entities/timeline_item.dart';
import '../repositories/place_search_repository.dart';

class GetPlaceCandidatesUseCase {

  final PlaceSearchRepository repository;

  GetPlaceCandidatesUseCase(
      this.repository,
      );

  /// 滞在場所ごとに、周辺の施設の候補を取得
  /// 戻り値は[stays]と同じ順番(検索できなかった場所は、候補なしになる)
  Future<List<List<PlaceCandidate>>> execute(
      List<Stay> stays,
      ) async {
    if (stays.isEmpty) return [];

    final candidates = await repository.findNearby([
      for (final stay in stays)
        (latitude: stay.latitude, longitude: stay.longitude),
    ]);

    return [for (final e in candidates) e ?? const []];
  }
}
