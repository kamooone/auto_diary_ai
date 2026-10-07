import '../entities/place_candidate.dart';

typedef Coordinate = ({double latitude, double longitude});

/// 周辺の施設を検索する
///
/// 情報源(OpenStreetMapなど)は実装側で差し替えられる
abstract class PlaceSearchRepository {
  /// それぞれの座標の周辺にある施設の候補を、近い順に取得
  /// 戻り値は[coordinates]と同じ順番。周辺に施設がない場合は空のリストになる
  ///
  /// 検索に失敗した場合は[PlaceSearchException]を投げる
  Future<List<List<PlaceCandidate>>> findNearby(List<Coordinate> coordinates);
}
