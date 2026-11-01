/// カレンダーに並べる月と、1か月分の日付の並び
class MonthGrid {
  const MonthGrid._();

  /// 表示できる月(新しい順)。[oldest]の月から[now]の月まで。
  /// 日記がない(oldestがnull)ときは、今月だけ
  static List<DateTime> months({DateTime? oldest, required DateTime now}) {
    final last = DateTime(now.year, now.month);
    final first = oldest == null || oldest.isAfter(last)
        ? last
        : DateTime(oldest.year, oldest.month);

    final months = <DateTime>[];
    for (var m = last; !m.isBefore(first); m = DateTime(m.year, m.month - 1)) {
      months.add(m);
    }
    return months;
  }

  /// 1か月分のセル(日曜はじまり)。月の前後の空きはnull。
  /// 長さは、いつも7の倍数
  static List<DateTime?> cells(DateTime month) {
    final first = DateTime(month.year, month.month);
    final days = DateTime(month.year, month.month + 1, 0).day;

    // DateTime.weekdayは月曜=1〜日曜=7。日曜はじまりにするため、日曜を0にする
    final leading = first.weekday % 7;

    final cells = <DateTime?>[
      for (var i = 0; i < leading; i++) null,
      for (var d = 1; d <= days; d++) DateTime(month.year, month.month, d),
    ];
    while (cells.length % 7 != 0) {
      cells.add(null);
    }
    return cells;
  }
}
