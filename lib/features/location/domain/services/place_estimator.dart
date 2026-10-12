import '../entities/place_candidate.dart';

/// 周辺の施設の候補から、訪れた施設を推定する
class PlaceEstimator {
  /// 訪れたとみなす施設(近くに施設がない場合はnull)
  ///
  /// [candidates]は近い順に並んでいること。候補は検索の範囲内(滞在場所の周辺)の
  /// 施設なので、最も近いものを訪れた施設とみなす。違っていれば、ユーザーが候補から選び直す
  PlaceCandidate? estimate(List<PlaceCandidate> candidates) {
    return candidates.firstOrNull;
  }
}
