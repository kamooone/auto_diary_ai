import 'package:isar/isar.dart';

import '../../domain/entities/x_archive_recall_settings.dart';
import '../models/x_archive_recall_settings_model.dart';

/// 通知の設定の保存と読み込み
class XArchiveRecallSettingsStore {
  final Isar isar;

  const XArchiveRecallSettingsStore(this.isar);

  Future<XArchiveRecallSettings> load() async {
    final model = await isar.xArchiveRecallSettingsModels.get(0);
    if (model == null) return const XArchiveRecallSettings();
    return XArchiveRecallSettings(
      enabled: model.enabled,
      hour: model.hour,
      minute: model.minute,
    );
  }

  Future<void> save(XArchiveRecallSettings settings) async {
    final model = XArchiveRecallSettingsModel()
      ..enabled = settings.enabled
      ..hour = settings.hour
      ..minute = settings.minute;
    await isar.writeTxn(() async {
      await isar.xArchiveRecallSettingsModels.put(model);
    });
  }
}
