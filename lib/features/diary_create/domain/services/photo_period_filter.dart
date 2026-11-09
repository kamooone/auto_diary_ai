/// 写真を選ぶ画面の、年と月による絞り込み
///
/// 年も月も未指定なら、すべての写真(期間の制限なし)
class PhotoPeriodFilter {
  final int? year;
  final int? month;

  const PhotoPeriodFilter({this.year, this.month});

  static const all = PhotoPeriodFilter();

  /// 日記の日付(または期間)に合わせた、初めの絞り込み
  ///
  /// 期間が1か月に収まるときは、その月。ほかは、始まりの年(日記の期間より広くても選べる)。
  /// 期間を渡さないときは、すべての写真
  factory PhotoPeriodFilter.initial({DateTime? from, DateTime? to}) {
    if (from == null) return all;

    // [to]は、期間の終わりの次の日の0時(その日は含まない)
    final last = (to ?? from).subtract(const Duration(seconds: 1));
    final lastDay = last.isBefore(from) ? from : last;

    if (from.year == lastDay.year && from.month == lastDay.month) {
      return PhotoPeriodFilter(year: from.year, month: from.month);
    }

    return PhotoPeriodFilter(year: from.year);
  }

  /// 年を変えると、月の指定は解除する
  PhotoPeriodFilter withYear(int? year) => PhotoPeriodFilter(year: year);

  PhotoPeriodFilter withMonth(int? month) =>
      PhotoPeriodFilter(year: year, month: month);

  /// 撮影日時の範囲([from]以上[to]未満)。すべての写真のときは、両方null
  DateTime? get from => year == null ? null : DateTime(year!, month ?? 1, 1);

  DateTime? get to {
    if (year == null) return null;

    return month == null ? DateTime(year! + 1, 1, 1) : DateTime(year!, month! + 1, 1);
  }

  /// 選択肢にする年(新しい年が先頭)。一番古い写真の年から、今年まで
  static List<int> years({required DateTime? oldest, required DateTime now}) {
    final first = oldest == null || oldest.year > now.year ? now.year : oldest.year;

    return [for (var y = now.year; y >= first; y--) y];
  }

  @override
  bool operator ==(Object other) =>
      other is PhotoPeriodFilter && other.year == year && other.month == month;

  @override
  int get hashCode => Object.hash(year, month);
}
