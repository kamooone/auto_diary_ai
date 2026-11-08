/// 日記の対象期間の表示
class DiaryPeriodText {
  DiaryPeriodText._();

  /// 1日分は「2026年1月1日」、複数日は「2026年1月1日〜1月3日(3日間)」の形にする
  static String format(DateTime start, DateTime end) {
    final first = "${start.year}年${start.month}月${start.day}日";

    if (start == end) return first;

    final days = end.difference(start).inDays + 1;
    final last = start.year == end.year
        ? "${end.month}月${end.day}日"
        : "${end.year}年${end.month}月${end.day}日";

    return "$first〜$last（$days日間）";
  }
}
