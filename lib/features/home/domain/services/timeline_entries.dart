import 'package:auto_diary_ai/features/diary/domain/entities/diary.dart';

/// ホーム画面のタイムラインの、1行分
class TimelineEntry {
  const TimelineEntry({
    required this.diary,
    required this.showDate,
    required this.isLatest,
  });

  final Diary diary;

  /// 日付と、丸い印を出すか(同じ日の2件目以降は、出さない)
  final bool showDate;

  /// いちばん新しい日記か(オレンジの印にする)
  final bool isLatest;
}

/// 1か月分の日記([items]は、新しい日付順)を、タイムラインの行にする
///
/// 同じ日に、複数の日記があるときは、日付と印は、1件目だけに出す。
/// [latest]は、全体でいちばん新しい日記(その月になければ、オレンジの印は出ない)
List<TimelineEntry> buildTimelineEntries(List<Diary> items, {Diary? latest}) {
  final entries = <TimelineEntry>[];
  DateTime? previousDay;

  for (final diary in items) {
    final day = DateTime(diary.date.year, diary.date.month, diary.date.day);
    entries.add(
      TimelineEntry(
        diary: diary,
        showDate: previousDay != day,
        isLatest: identical(diary, latest),
      ),
    );
    previousDay = day;
  }
  return entries;
}

/// 日記を書いた日の数(同じ日に、複数あっても、1日と数える)
int countRecordedDays(List<Diary> items) {
  return items
      .map((e) => DateTime(e.date.year, e.date.month, e.date.day))
      .toSet()
      .length;
}
