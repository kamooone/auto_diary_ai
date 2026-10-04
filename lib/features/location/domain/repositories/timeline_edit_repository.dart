import '../entities/timeline_edit.dart';

abstract class TimelineEditRepository {
  /// 指定した時間帯と重なる修正を取得
  Future<List<TimelineEdit>> findOverlapping(DateTime start, DateTime end);

  /// 修正を保存(idがある場合は上書き)
  Future<void> save(TimelineEdit edit);

  Future<void> delete(int id);
}
