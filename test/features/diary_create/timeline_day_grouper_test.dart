import 'package:auto_diary_ai/features/diary_create/domain/services/timeline_day_grouper.dart';
import 'package:auto_diary_ai/features/location/domain/entities/timeline_item.dart';
import 'package:flutter_test/flutter_test.dart';

Stay stay(DateTime start) {
  return Stay(
    start: start,
    end: start.add(const Duration(hours: 1)),
    latitude: 35.0,
    longitude: 139.0,
  );
}

void main() {
  final grouper = TimelineDayGrouper();

  test('行動履歴を日付ごとに分け、日付の古い順に並べる', () {
    final a = stay(DateTime(2026, 1, 3, 9));
    final b = stay(DateTime(2026, 1, 1, 10));
    final c = stay(DateTime(2026, 1, 3, 15));
    final d = stay(DateTime(2026, 1, 2, 8));

    final days = grouper.group([a, b, c, d]);

    expect(days.map((e) => e.date), [
      DateTime(2026, 1, 1),
      DateTime(2026, 1, 2),
      DateTime(2026, 1, 3),
    ]);
    // 同じ日の中は、渡された順のまま
    expect(days.last.items, [a, c]);
  });

  test('日付をまたいだ滞在は、開始した日にまとめる', () {
    final night = Stay(
      start: DateTime(2026, 1, 1, 22),
      end: DateTime(2026, 1, 2, 6),
      latitude: 35.0,
      longitude: 139.0,
    );

    final days = grouper.group([night]);

    expect(days.single.date, DateTime(2026, 1, 1));
  });

  test('行動履歴がなければ、空になる', () {
    expect(grouper.group([]), isEmpty);
  });
}
