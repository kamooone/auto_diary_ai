import '../entities/memo.dart';

/// ひとことメモを、AIに渡す文章にする(日時の古い順)
///
/// サーバーに送る内容と、消費トークンの見積もりの、両方で使う(同じ文章の長さで数えるため)
class MemoText {
  const MemoText._();

  /// 日時と本文を、メモごとに並べる(「2026-11-09 12:34」と、本文)
  static String format(List<Memo> memos) {
    final sorted = [...memos]..sort((a, b) => a.createdAt.compareTo(b.createdAt));

    return sorted.map((e) => "${_dateTime(e.createdAt)}\n${e.text.trim()}").join("\n\n");
  }

  static String _dateTime(DateTime t) {
    String two(int n) => n.toString().padLeft(2, '0');

    return "${t.year}-${two(t.month)}-${two(t.day)} ${two(t.hour)}:${two(t.minute)}";
  }
}
