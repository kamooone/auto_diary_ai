import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:isar/isar.dart';
import 'package:permission_handler/permission_handler.dart';
import '../datasources/activity_recorder_datasource.dart';
import '../models/activity_log.dart';

final _recorder = ActivityRecorderDataSource();

// 取り込みが同時に走らないよう、前の取り込みの完了を待つ
Future<void> _importing = Future.value();

const _fetchTimeout = Duration(seconds: 30);

bool get _isSupported => Platform.isAndroid || Platform.isIOS;

/// 行動認識(徒歩・自転車・乗り物など)の記録を開始する
///
/// Android: 身体活動の許可を求め、行動の変化の通知を登録する
/// iOS: 履歴を後から取得するため登録は不要。最初の取り込みで許可ダイアログが
///      表示されるので、他の許可と同じく起動時に求めるよう、ここで取り込みを行う
Future<void> startActivityRecording(Isar isar) async {
  if (!_isSupported) return;

  try {
    if (Platform.isAndroid) {
      final status = await Permission.activityRecognition.request();
      if (!status.isGranted) return;
    }

    await _recorder.start();
  } catch (e) {
    debugPrint('行動認識を開始できませんでした: $e');
    return;
  }

  await importRecordedActivities(isar);
}

/// ネイティブ側の行動の記録をIsarへ取り込む
Future<void> importRecordedActivities(Isar isar) {
  if (!_isSupported) return Future.value();

  return _importing = _importing.then((_) async {
    try {
      final latest =
          await isar.activityLogs.where().sortByTimestampDesc().findFirst();

      // ネイティブ側から応答が返らない場合でも、起動やタイムラインの表示を止めない
      final records = await _recorder
          .fetchNew(latest?.timestamp)
          .timeout(_fetchTimeout)
        ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

      // 取り込み済みの記録と、同じ行動が続いているだけの記録は保存しない
      final logs = <ActivityLog>[];
      var lastType = latest?.type;

      for (final record in records) {
        if (latest != null && !record.timestamp.isAfter(latest.timestamp)) {
          continue;
        }
        if (record.type == lastType) continue;

        lastType = record.type;
        logs.add(record);
      }

      if (logs.isNotEmpty) {
        await isar.writeTxn(() async {
          await isar.activityLogs.putAll(logs);
        });
      }

      await _recorder.confirm();
    } catch (e) {
      debugPrint('行動の記録の取り込みに失敗しました: $e');
    }
  });
}
