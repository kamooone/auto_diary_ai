import '../entities/timeline_item.dart';

/// 計算済みのタイムラインの保存先
///
/// 過去の日のタイムラインは内容が変わらないため、地名や施設の取得まで済んだ結果を
/// 保存しておき、次回からは計算や問い合わせをせずに表示する。
/// ユーザーの修正(場所名・移動手段)は含めず、読み出した後に当てはめる。
abstract class TimelineSnapshotRepository {
  /// 保存済みのタイムラインを取得(保存されていない場合はnull)
  ///
  /// [locationCount]はその日の位置情報の件数。保存した時点から件数が変わっている場合は、
  /// 後から位置情報が届いたとみなして使わない
  Future<List<TimelineItem>?> find(
    DateTime date, {
    required int locationCount,
  });

  Future<void> save(
    DateTime date,
    List<TimelineItem> items, {
    required int locationCount,
  });
}
