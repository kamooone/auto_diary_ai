import '../entities/place_candidate.dart';
import '../entities/timeline_item.dart';
import '../repositories/place_search_repository.dart';
import '../repositories/registered_place_repository.dart';
import '../services/registered_place_finder.dart';

class GetPlaceCandidatesUseCase {

  final PlaceSearchRepository repository;

  final RegisteredPlaceRepository registeredPlaceRepository;

  final RegisteredPlaceFinder _finder = RegisteredPlaceFinder();

  GetPlaceCandidatesUseCase(
      this.repository,
      this.registeredPlaceRepository,
      );

  /// 滞在場所ごとに、周辺の施設の候補を取得
  /// 戻り値は[stays]と同じ順番(検索できなかった場所は、候補なしになる)
  ///
  /// 登録した場所は、名前が決まっているため検索しない(候補なしになる)
  Future<List<List<PlaceCandidate>>> execute(
      List<Stay> stays,
      ) async {
    if (stays.isEmpty) return [];

    final registered = await registeredPlaceRepository.getAll();

    final targets = [
      for (final stay in stays)
        if (_finder.find(stay, registered) == null) stay,
    ];

    final found = targets.isEmpty
        ? <List<PlaceCandidate>?>[]
        : await repository.findNearby([
            for (final stay in targets)
              (latitude: stay.latitude, longitude: stay.longitude),
          ]);

    final candidates = <Stay, List<PlaceCandidate>>{
      for (var i = 0; i < targets.length; i++) targets[i]: found[i] ?? const [],
    };

    return [for (final stay in stays) candidates[stay] ?? const []];
  }
}
