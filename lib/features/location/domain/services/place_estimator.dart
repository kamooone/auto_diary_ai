import '../entities/place_candidate.dart';

/// 周辺の施設の候補から、訪れた施設を推定する
class PlaceEstimator {
  // 滞在場所からこの距離以内にある最も近い施設を、訪れた施設とみなす
  static const _maxDistanceMeters = 50.0;

  /// 訪れたとみなす施設(近くに施設がない場合はnull)
  /// [candidates]は近い順に並んでいること
  PlaceCandidate? estimate(List<PlaceCandidate> candidates) {
    if (candidates.isEmpty) return null;

    final nearest = candidates.first;
    return nearest.distanceMeters <= _maxDistanceMeters ? nearest : null;
  }
}
