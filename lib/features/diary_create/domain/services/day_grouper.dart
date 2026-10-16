/// 1日分の項目
class DayGroup<T> {
  /// 日付(0時)
  final DateTime date;

  final List<T> items;

  const DayGroup({required this.date, required this.items});
}

/// 項目を、[timeOf]が返す時刻の日付ごとに分ける
/// (日付の古い順。同じ日の中は、渡された順のまま)
List<DayGroup<T>> groupByDay<T>(
  List<T> items,
  DateTime Function(T item) timeOf,
) {
  final byDay = <DateTime, List<T>>{};

  for (final item in items) {
    final time = timeOf(item);
    final day = DateTime(time.year, time.month, time.day);
    byDay.putIfAbsent(day, () => []).add(item);
  }

  final days = byDay.keys.toList()..sort();

  return [
    for (final day in days) DayGroup(date: day, items: byDay[day]!),
  ];
}
