import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import 'app_info.dart';

/// アプリを使い始めた日
///
/// 保存された値を`main()`で読み込み、`ProviderScope.overrides`で注入する。
final installDateProvider = StateProvider<DateTime>((ref) {
  throw UnimplementedError();
});

/// 使い始めた日を、[date]まで早める(すでに[date]より前なら、何もしない)
///
/// テスト用のデータなど、使い始める前の日付のデータを選べるようにするために使う
Future<void> moveInstallDateEarlier(
  Isar isar,
  StateController<DateTime> state,
  DateTime date,
) async {
  if (!date.isBefore(state.state)) return;

  await isar.writeTxn(() async {
    await isar.appInfos.put(AppInfo()..installedAt = date);
  });
  state.state = date;
}

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
