abstract class PlaceNameRepository {
  /// 座標から地名を取得(取得できない場合はnull)
  Future<String?> getPlaceName(double latitude, double longitude);
}
