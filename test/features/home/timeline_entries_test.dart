import 'package:auto_diary_ai/features/diary/domain/entities/diary.dart';
import 'package:auto_diary_ai/features/home/domain/services/timeline_entries.dart';
import 'package:flutter_test/flutter_test.dart';

Diary diary(int day, {int hour = 9, bool ai = false}) => Diary(
  date: DateTime(2026, 10, day, hour),
  title: '日記$day-$hour',
  content: '',
  isAiGenerated: ai,
  createdAt: DateTime(2026, 10, day, hour),
);

void main() {
  test('同じ日の2件目以降は、日付と印を出さない', () {
    final items = [
      diary(27),
      diary(26, hour: 20),
      diary(26, hour: 8),
      diary(25),
    ];

    final entries = buildTimelineEntries(items);

    expect(entries.map((e) => e.showDate), [true, true, false, true]);
  });

  test('全体でいちばん新しい日記だけが、オレンジの印になる', () {
    final newest = diary(27);
    final items = [newest, diary(26), diary(25)];

    final entries = buildTimelineEntries(items, latest: newest);

    expect(entries.map((e) => e.isLatest), [true, false, false]);
  });

  test('その月に、いちばん新しい日記がなければ、オレンジの印は出ない', () {
    final items = [diary(10), diary(9)];

    final entries = buildTimelineEntries(items, latest: diary(27));

    expect(entries.any((e) => e.isLatest), isFalse);
  });

  test('記録の日数は、同じ日に複数あっても1日と数える', () {
    final items = [diary(27), diary(26, hour: 20), diary(26, hour: 8)];

    expect(countRecordedDays(items), 2);
    expect(countRecordedDays(const []), 0);
  });
}
