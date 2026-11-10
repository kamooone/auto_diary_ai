/// 取り込んだXの投稿の、年・月・日(日本時間)と検索語による絞り込み
class XArchivePostFilter {
  final int? year;
  final int? month;
  final int? day;

  /// 検索語。空白(全角も可)で区切ると、すべての語を含む投稿を探す
  final String query;

  const XArchivePostFilter({this.year, this.month, this.day, this.query = ''});

  static const none = XArchivePostFilter();

  /// 年を変えると、月と日の指定は解除する
  XArchivePostFilter withYear(int? year) =>
      XArchivePostFilter(year: year, query: query);

  /// 月を変えると、日の指定は解除する
  XArchivePostFilter withMonth(int? month) =>
      XArchivePostFilter(year: year, month: month, query: query);

  XArchivePostFilter withDay(int? day) =>
      XArchivePostFilter(year: year, month: month, day: day, query: query);

  XArchivePostFilter withQuery(String query) =>
      XArchivePostFilter(year: year, month: month, day: day, query: query);

  /// 何も絞り込んでいないか
  bool get isNone => year == null && words.isEmpty;

  static const _jst = Duration(hours: 9);

  /// 期間の始まり(UTC。この日時を含む)。年を選んでいないときはnull
  DateTime? get from {
    final y = year;
    if (y == null) return null;
    return DateTime.utc(y, month ?? 1, day ?? 1).subtract(_jst);
  }

  /// 期間の終わり(UTC。この日時は含まない)。年を選んでいないときはnull
  DateTime? get to {
    final y = year;
    if (y == null) return null;
    final m = month;
    final d = day;
    final DateTime next;
    if (m != null && d != null) {
      next = DateTime.utc(y, m, d + 1);
    } else if (m != null) {
      next = DateTime.utc(y, m + 1, 1);
    } else {
      next = DateTime.utc(y + 1, 1, 1);
    }
    return next.subtract(_jst);
  }

  /// 小文字にして、空白で区切った検索語
  List<String> get words => query
      .toLowerCase()
      .split(RegExp(r'[\s　]+'))
      .where((e) => e.isNotEmpty)
      .toList();

  /// [year]年[month]月の日数
  static int daysInMonth(int year, int month) =>
      DateTime.utc(year, month + 1, 0).day;

  @override
  bool operator ==(Object other) =>
      other is XArchivePostFilter &&
      other.year == year &&
      other.month == month &&
      other.day == day &&
      other.query == query;

  @override
  int get hashCode => Object.hash(year, month, day, query);
}
