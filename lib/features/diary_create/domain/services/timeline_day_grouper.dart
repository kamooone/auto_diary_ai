import '../../../location/domain/entities/timeline_item.dart';

/// 1日分の行動履歴
class TimelineDay {
  /// 日付(0時)
  final DateTime date;

  final List<TimelineItem> items;

  const TimelineDay({required this.date, required this.items});
}

/// 行動履歴を、日付ごとに分ける
class TimelineDayGrouper {
  /// 開始時刻の日付ごとに分ける(日付の古い順。同じ日の中は、渡された順のまま)
  List<TimelineDay> group(List<TimelineItem> items) {
    final byDay = <DateTime, List<TimelineItem>>{};

    for (final item in items) {
      final day = DateTime(item.start.year, item.start.month, item.start.day);
      byDay.putIfAbsent(day, () => []).add(item);
    }

    final days = byDay.keys.toList()..sort();

    return [
      for (final day in days) TimelineDay(date: day, items: byDay[day]!),
    ];
  }
}
