import 'package:isar/isar.dart';

part 'diary_log.g.dart';

/// 保存した日記
@collection
class DiaryLog {
  Id id = Isar.autoIncrement;

  /// 日記の日付
  @Index()
  late DateTime date;

  late String title;
  late String content;

  /// AIが書いた日記かどうか
  late bool isAiGenerated;

  /// 日記に添えた写真のID
  late List<String> photoIds;

  late DateTime createdAt;
}
