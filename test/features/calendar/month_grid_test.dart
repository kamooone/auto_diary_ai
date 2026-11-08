import 'package:auto_diary_ai/features/calendar/domain/services/month_grid.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MonthGrid.months', () {
    test('今月から、日記のある一番古い月まで、新しい順に並ぶ', () {
      final months = MonthGrid.months(
        oldest: DateTime(2025, 11, 20),
        now: DateTime(2026, 2, 3),
      );

      expect(months, [
        DateTime(2026, 2),
        DateTime(2026, 1),
        DateTime(2025, 12),
        DateTime(2025, 11),
      ]);
    });

    test('日記がなければ今月だけ', () {
      expect(MonthGrid.months(now: DateTime(2026, 2, 3)), [DateTime(2026, 2)]);
    });
  });

  group('MonthGrid.cells', () {
    test('日曜はじまりで、月の前後の空きはnull(2026年11月は日曜はじまり)', () {
      final cells = MonthGrid.cells(DateTime(2026, 11));

      expect(cells.first, DateTime(2026, 11, 1));
      expect(cells.where((e) => e != null).length, 30);
      expect(cells.length % 7, 0);
    });

    test('月初が木曜なら、前に4つ空きが入る(2026年10月)', () {
      final cells = MonthGrid.cells(DateTime(2026, 10));

      expect(cells.take(4), everyElement(isNull));
      expect(cells[4], DateTime(2026, 10, 1));
      expect(cells.where((e) => e != null).length, 31);
    });
  });
}
