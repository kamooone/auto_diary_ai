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

  return [for (final day in days) DayGroup(date: day, items: byDay[day]!)];
}

/// 1か月分の項目(選択画面の、月ごとの見出しの行に使う)
class MonthGroup<T> {
  const MonthGroup(this.month, this.items);

  /// 月(1日の0時)
  final DateTime month;

  final List<T> items;
}

/// 選択画面の行を、月の見出し([MonthGroup])、日付の見出し([DayGroup])、項目の順に、
/// 1列に並べる。[expandedMonths]に入っていない月は、見出しだけを出す(アコーディオン)
List<Object> buildMonthRows<T extends Object>(
  List<DayGroup<T>> days,
  Set<DateTime> expandedMonths,
) {
  final rows = <Object>[];
  DateTime? currentMonth;

  for (final day in days) {
    final month = DateTime(day.date.year, day.date.month);

    if (month != currentMonth) {
      currentMonth = month;
      rows.add(
        MonthGroup<T>(month, [
          for (final d in days)
            if (d.date.year == month.year && d.date.month == month.month)
              ...d.items,
        ]),
      );
    }

    if (expandedMonths.contains(month)) rows.addAll([day, ...day.items]);
  }

  return rows;
}
