import 'package:isar/isar.dart';

part 'app_info.g.dart';

/// アプリ全体で1件だけ保存する情報
@collection
class AppInfo {
  Id id = 0;

  /// アプリを使い始めた日時
  late DateTime installedAt;
}
