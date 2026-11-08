import 'package:isar/isar.dart';

part 'timeline_snapshot.g.dart';

/// 計算済みの1日分のタイムライン
@collection
class TimelineSnapshot {
  Id id = Isar.autoIncrement;

  /// 対象の日(その日の0時)
  @Index()
  late DateTime date;

  /// 保存したときの計算方法の版
  /// 滞在や移動の判定を変えた場合に版を上げると、古い結果は使われなくなる
  late int version;

  /// 保存したときの、計算のもとになった位置情報を表す文字列
  String? signature;

  /// 滞在と移動の一覧(JSON)
  late String itemsJson;

  late DateTime savedAt;
}
