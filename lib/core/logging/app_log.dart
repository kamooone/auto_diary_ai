import 'package:flutter/foundation.dart';

/// 動作確認用のログ(画面にも表示する)
class AppLog {
  AppLog._();

  // 保持する件数(古いものから捨てる)
  static const _maxEntries = 200;

  static final entries = ValueNotifier<List<String>>(const []);

  /// 時刻つきで1行追加する
  static void add(String tag, String message) {
    final now = DateTime.now();
    String two(int n) => n.toString().padLeft(2, '0');
    final time = '${two(now.hour)}:${two(now.minute)}:${two(now.second)}'
        '.${now.millisecond.toString().padLeft(3, '0')}';

    final line = '$time [$tag] $message';
    debugPrint(line);

    final next = [...entries.value, line];
    entries.value = next.length > _maxEntries
        ? next.sublist(next.length - _maxEntries)
        : next;
  }

  static void clear() => entries.value = const [];

  /// [action]の所要時間をログに残す(失敗した場合もその時間を残す)
  static Future<T> measure<T>(
    String tag,
    String label,
    Future<T> Function() action,
  ) async {
    // 終わらない処理がどこで止まっているか分かるよう、開始も残す
    add(tag, '▶ $label');

    final stopwatch = Stopwatch()..start();
    try {
      final result = await action();
      add(tag, '$label: ${stopwatch.elapsedMilliseconds}ms');
      return result;
    } catch (e) {
      add(tag, '$label: 失敗 ${stopwatch.elapsedMilliseconds}ms ($e)');
      rethrow;
    }
  }
}
