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
}
