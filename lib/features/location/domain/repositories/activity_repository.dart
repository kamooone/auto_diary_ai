import '../entities/activity_segment.dart';

abstract class ActivityRepository {
  /// 指定した時間帯の行動(徒歩・自転車・乗り物など)を取得
  /// 行動認識を利用できない場合は空のリストになる
  Future<List<ActivitySegment>> getActivities(DateTime start, DateTime end);
}
