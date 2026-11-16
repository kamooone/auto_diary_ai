import '../entities/memo.dart';

/// ひとことの一覧(タイムライン)の、1行分
class MemoTimelineItem {
  const MemoTimelineItem({
    required this.memo,
    required this.showDate,
    required this.showMonth,
  });

  final Memo memo;

  /// 日付と、丸い印を出すか(同じ日の2件目以降は、出さない)
  final bool showDate;

  /// この行の上に、「2026年10月」の見出しを出すか(月が変わるところ)
  final bool showMonth;
}

/// ひとこと([memos]は、新しい順)を、タイムラインの行にする
List<MemoTimelineItem> buildMemoTimeline(List<Memo> memos) {
  final items = <MemoTimelineItem>[];
  DateTime? previousDay;
  DateTime? previousMonth;

  for (final memo in memos) {
    final t = memo.createdAt;
    final day = DateTime(t.year, t.month, t.day);
    final month = DateTime(t.year, t.month);

    items.add(
      MemoTimelineItem(
        memo: memo,
        showDate: previousDay != day,
        showMonth: previousMonth != month,
      ),
    );
    previousDay = day;
    previousMonth = month;
  }
  return items;
}
