import 'package:auto_diary_ai/features/memo/domain/entities/memo.dart';
import 'package:auto_diary_ai/features/memo/domain/services/memo_timeline.dart';
import 'package:flutter_test/flutter_test.dart';

Memo memo(int month, int day, int hour) => Memo(
  text: '$month/$day $hour',
  createdAt: DateTime(2026, month, day, hour),
);

void main() {
  test('同じ日の2件目以降は、日付を出さない', () {
    final items = buildMemoTimeline([
      memo(10, 27, 20),
      memo(10, 27, 9),
      memo(10, 26, 12),
    ]);

    expect(items.map((e) => e.showDate), [true, false, true]);
  });

  test('月が変わるところだけ、月の見出しを出す', () {
    final items = buildMemoTimeline([
      memo(10, 2, 9),
      memo(10, 1, 9),
      memo(9, 30, 9),
      memo(9, 1, 9),
    ]);

    expect(items.map((e) => e.showMonth), [true, false, true, false]);
  });

  test('空のときは、空', () {
    expect(buildMemoTimeline(const []), isEmpty);
  });
}
