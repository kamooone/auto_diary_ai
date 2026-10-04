import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import 'app_info.dart';

/// アプリを使い始めた日
///
/// 保存された値を`main()`で読み込み、`ProviderScope.overrides`で注入する。
final installDateProvider = Provider<DateTime>((ref) {
  throw UnimplementedError();
});

/// アプリを使い始めた日を取得する(まだ保存されていない場合は保存する)
///
/// この値を保存する前から使っている場合に備えて、[earliestRecord]に最も古い記録の
/// 日時を渡すと、それを使い始めた日として保存する
Future<DateTime> loadInstallDate(
  Isar isar, {
  DateTime? earliestRecord,
}) async {
  final info = await isar.appInfos.get(0);
  if (info != null) return info.installedAt;

  final installedAt = earliestRecord ?? DateTime.now();

  await isar.writeTxn(() async {
    await isar.appInfos.put(AppInfo()..installedAt = installedAt);
  });

  return installedAt;
}
