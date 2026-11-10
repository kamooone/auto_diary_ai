import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/isar_provider.dart';
import '../../data/repositories/x_archive_recall_settings_store.dart';
import '../../domain/entities/x_archive_recall.dart';
import '../../domain/entities/x_archive_recall_settings.dart';
import '../../domain/repositories/x_archive_repository.dart';
import '../services/x_archive_recall_builder.dart';
import '../services/x_archive_recall_notifier.dart';
import 'x_archive_providers.dart';

final xArchiveRecallNotifierProvider = Provider<XArchiveRecallNotifier>((ref) {
  return XArchiveRecallNotifier();
});

final xArchiveRecallSettingsStoreProvider =
    Provider<XArchiveRecallSettingsStore>((ref) {
  return XArchiveRecallSettingsStore(ref.watch(isarProvider));
});

final xArchiveRecallBuilderProvider = Provider<XArchiveRecallBuilder>((ref) {
  return XArchiveRecallBuilder(ref.watch(xArchiveRepositoryProvider));
});

/// 通知の設定。変えたあとは ref.invalidate で読み込み直す
final xArchiveRecallSettingsProvider =
    FutureProvider.autoDispose<XArchiveRecallSettings>((ref) {
  return ref.watch(xArchiveRecallSettingsStoreProvider).load();
});

/// 通知にできる投稿があるか(取り込み済みの、通常の投稿と引用が1件以上)
final xArchiveRecallAvailableProvider = FutureProvider.autoDispose<bool>((ref) async {
  return await ref.watch(xArchiveRepositoryProvider).countOriginals() > 0;
});

/// 「過去のツイート紹介」の中身。[date] を渡さなければ、日本時間の今日
final xArchiveRecallProvider =
    FutureProvider.autoDispose.family<XArchiveRecall, DateTime?>((ref, date) {
  final DateTime day;
  if (date != null) {
    day = DateTime(date.year, date.month, date.day);
  } else {
    final jst = DateTime.now().toUtc().add(const Duration(hours: 9));
    day = DateTime(jst.year, jst.month, jst.day);
  }
  return ref.watch(xArchiveRecallBuilderProvider).build(day);
});

/// アプリの起動時に、保存した設定と通知の予約をそろえる
///
/// 投稿を全部消したあとなど、通知にできる投稿がないときは、通知を止めて設定もオフにする
Future<void> syncXArchiveRecallNotification({
  required XArchiveRecallSettingsStore store,
  required XArchiveRecallNotifier notifier,
  required XArchiveRepository repository,
}) async {
  final settings = await store.load();
  if (!settings.enabled) return;

  if (await repository.countOriginals() == 0) {
    await notifier.cancel();
    await store.save(settings.copyWith(enabled: false));
    return;
  }
  await notifier.schedule(hour: settings.hour, minute: settings.minute);
}
