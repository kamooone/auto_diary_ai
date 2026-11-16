import 'package:auto_diary_ai/features/home/domain/services/home_months.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('いちばん古い日記の月から、今月まで、日記のない月も含めて、新しい月が先頭', () {
    final months = homeMonths(
      diaryDates: [DateTime(2026, 8, 20), DateTime(2026, 10, 27)],
      now: DateTime(2026, 11, 16),
    );

    expect(months, ['2026-11', '2026-10', '2026-09', '2026-08']);
  });

  test('今月に日記がなくても、今月が先頭になる', () {
    final months = homeMonths(
      diaryDates: [DateTime(2026, 10, 27)],
      now: DateTime(2026, 11, 16),
    );

    expect(months.first, '2026-11');
  });

  test('年をまたいでも、すべての月が並ぶ', () {
    final months = homeMonths(
      diaryDates: [DateTime(2025, 11, 3)],
      now: DateTime(2026, 2, 1),
    );

    expect(months, ['2026-02', '2026-01', '2025-12', '2025-11']);
  });

  test('今月より先の日付の日記があるときは、その月まで並べる', () {
    final months = homeMonths(
      diaryDates: [DateTime(2026, 12, 5), DateTime(2026, 10, 1)],
      now: DateTime(2026, 11, 16),
    );

    expect(months.first, '2026-12');
    expect(months.last, '2026-10');
  });

  test('日記が1件もないときは、空', () {
    expect(
      homeMonths(diaryDates: const [], now: DateTime(2026, 11, 16)),
      isEmpty,
    );
  });
}
