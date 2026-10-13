import 'package:auto_diary_ai/core/async/parallel.dart';
import 'package:auto_diary_ai/core/logging/app_log.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('parallelMap', () {
    test('同時に処理する数を制限し、結果は元の順番で返す', () async {
      var running = 0;
      var maxRunning = 0;

      final results = await parallelMap<int, int>(
        [for (var i = 0; i < 10; i++) i],
        (i) async {
          running++;
          if (running > maxRunning) maxRunning = running;
          // 後ろの要素ほど先に終わるようにする
          await Future<void>.delayed(Duration(milliseconds: 20 - i));
          running--;
          return i * 2;
        },
        concurrency: 3,
      );

      expect(maxRunning, 3);
      expect(results, [for (var i = 0; i < 10; i++) i * 2]);
    });

    test('空のリストでも動く', () async {
      expect(await parallelMap<int, int>([], (i) async => i), isEmpty);
    });
  });

  group('AppLog', () {
    setUp(AppLog.clear);

    test('時刻とタグつきで追加し、古いものから捨てる', () {
      for (var i = 0; i < 250; i++) {
        AppLog.add('テスト', '$i');
      }

      final entries = AppLog.entries.value;
      expect(entries, hasLength(200));
      expect(entries.last, contains('[テスト] 249'));
      expect(entries.first, contains('[テスト] 50'));
    });

    test('measureは所要時間を残し、失敗しても例外をそのまま投げる', () async {
      expect(await AppLog.measure('t', '成功', () async => 1), 1);
      expect(AppLog.entries.value.last, matches(r'\[t\] 成功: \d+ms'));

      await expectLater(
        AppLog.measure('t', '失敗', () async => throw StateError('x')),
        throwsStateError,
      );
      expect(AppLog.entries.value.last, contains('失敗: 失敗'));
    });
  });
}
