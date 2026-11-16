/// ホーム画面で、切り替えられる月(「2026-10」の形。新しい月が先頭)
///
/// いちばん古い日記の月から、今月までを、日記のない月も含めて、すべて並べる。
/// 日記が1件もないときは、空(「まだ日記がありません」を出す)。
/// 今月より先の日付の日記があるときは、その月まで並べる
List<String> homeMonths({
  required Iterable<DateTime> diaryDates,
  required DateTime now,
}) {
  DateTime? oldest;
  DateTime? newest;
  for (final date in diaryDates) {
    final month = DateTime(date.year, date.month);
    if (oldest == null || month.isBefore(oldest)) oldest = month;
    if (newest == null || month.isAfter(newest)) newest = month;
  }
  if (oldest == null || newest == null) return const [];

  final thisMonth = DateTime(now.year, now.month);
  final last = newest.isAfter(thisMonth) ? newest : thisMonth;

  final months = <String>[];
  for (var m = last; !m.isBefore(oldest); m = DateTime(m.year, m.month - 1)) {
    months.add('${m.year}-${m.month.toString().padLeft(2, '0')}');
  }
  return months;
}
