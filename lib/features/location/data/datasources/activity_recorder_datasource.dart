import 'package:flutter/services.dart';
import '../models/activity_log.dart';

/// ネイティブ側の行動認識(徒歩・自転車・乗り物など)
///
/// Android: 行動が変わるたびにOSから通知を受け、ネイティブ側がファイルに溜める
/// iOS: OSが保持している約7日分の履歴を後から取得する
class ActivityRecorderDataSource {
  static const _channel = MethodChannel('auto_diary_ai/activity_recorder');

  /// 記録を開始する(行動認識を利用できない場合はfalse)
  Future<bool> start() async {
    return await _channel.invokeMethod<bool>('start') ?? false;
  }

  /// まだ取り込んでいない行動の変化を取得する
  /// 保存が完了したら[confirm]を呼ぶこと
  Future<List<ActivityLog>> fetchNew(DateTime? since) async {
    final records = await _channel.invokeListMethod<Map<Object?, Object?>>(
      'fetchNew',
      {'since': since?.millisecondsSinceEpoch},
    );

    return [
      for (final record in records ?? const <Map<Object?, Object?>>[])
        ActivityLog()
          ..type = record['type'] as String
          ..timestamp = DateTime.fromMillisecondsSinceEpoch(
            (record['timestamp'] as num).toInt(),
          ),
    ];
  }

  /// 取得した記録をネイティブ側から削除する
  Future<void> confirm() {
    return _channel.invokeMethod<void>('confirm');
  }
}
