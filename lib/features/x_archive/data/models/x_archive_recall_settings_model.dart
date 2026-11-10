import 'package:isar/isar.dart';
part 'x_archive_recall_settings_model.g.dart';

/// 過去のツイートの通知の設定(1件だけ保存する)
@collection
class XArchiveRecallSettingsModel {
  Id id = 0;

  bool enabled = false;

  /// 通知する時刻(日本時間)
  int hour = 20;
  int minute = 0;

  XArchiveRecallSettingsModel();
}
