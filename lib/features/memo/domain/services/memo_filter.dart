import '../../../diary_create/domain/services/photo_period_filter.dart';
import '../entities/memo.dart';

/// ひとことメモの一覧の、年・月と文字による絞り込み
class MemoFilter {
  const MemoFilter._();

  /// [period]の年・月に入り、[query]の言葉をすべて含むメモだけを、順番そのままで返す
  ///
  /// [query]は、空白(全角も可)で区切ると、すべての言葉を含むものを探す。大文字・小文字は区別しない
  static List<Memo> apply(
    List<Memo> memos, {
    PhotoPeriodFilter period = PhotoPeriodFilter.all,
    String query = '',
  }) {
    final from = period.from;
    final to = period.to;
    final words = query
        .toLowerCase()
        .split(RegExp(r'[\s　]+'))
        .where((e) => e.isNotEmpty)
        .toList();

    return memos.where((memo) {
      if (from != null && memo.createdAt.isBefore(from)) return false;
      if (to != null && !memo.createdAt.isBefore(to)) return false;

      final text = memo.text.toLowerCase();
      return words.every(text.contains);
    }).toList();
  }

  /// 選択肢にする年(新しい年が先頭)。メモのある年だけ
  static List<int> years(List<Memo> memos) {
    final years = memos.map((e) => e.createdAt.year).toSet().toList()
      ..sort((a, b) => b.compareTo(a));
    return years;
  }
}
