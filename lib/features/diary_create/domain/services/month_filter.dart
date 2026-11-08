/// 年と月による絞り込み(どちらも未指定なら、すべて表示する)
class MonthFilter {
  final int? year;
  final int? month;

  const MonthFilter({this.year, this.month});

  static const none = MonthFilter();

  bool get isActive => year != null;

  bool matches(DateTime time) {
    if (year != null && time.year != year) return false;
    if (month != null && time.month != month) return false;
    return true;
  }

  /// 年を変えると、月の指定は解除する
  MonthFilter withYear(int? year) => MonthFilter(year: year);

  MonthFilter withMonth(int? month) => MonthFilter(year: year, month: month);

  /// 絞り込みに使う年と月の選択肢(古い順。月は1月、2月、3月…の順)
  static List<int> yearsOf(Iterable<DateTime> times) =>
      times.map((e) => e.year).toSet().toList()..sort();

  static List<int> monthsOf(Iterable<DateTime> times, int year) =>
      times.where((e) => e.year == year).map((e) => e.month).toSet().toList()
        ..sort();
}
