import '../entities/location.dart';

abstract class LocationRepository {
  /// GPS開始
  Stream<Location> startTracking();

  /// 全件取得
  Future<List<Location>> getLocations();

  /// 日付取得
  Future<List<Location>> getLocationsByDate(DateTime date);

  /// 最新取得
  Future<Location?> getLatestLocation();

  /// 指定した時刻より前の、最後の位置
  Future<Location?> getLastLocationBefore(DateTime time);

  /// [start]から[end]までの間の位置を削除する
  /// [includeEdges]がfalseの場合は、[start]と[end]ちょうどの位置は残す
  Future<void> deleteLocations(
    DateTime start,
    DateTime end, {
    bool includeEdges = true,
  });

  /// 指定した時刻以降の、最初の位置
  Future<Location?> getFirstLocationFrom(DateTime time);
}
