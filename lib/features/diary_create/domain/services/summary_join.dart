import '../../../diary/domain/entities/diary.dart';
import 'summary_text.dart';

/// 「日記を連結させる」。AIを使わずに、選んだ日記を日付順にそのままつなげる
class SummaryJoin {
  const SummaryJoin._();

  /// 日付・タイトル・本文を、日付の古い順に並べた本文
  static String content(List<Diary> diaries) => SummaryText.format(diaries);

  /// 期間から付けるタイトル(例: 「2026年1月の日記」「2025年12月〜2026年1月の日記」)
  static String title(List<Diary> diaries) {
    if (diaries.isEmpty) return "日記";

    final sorted = SummaryText.sorted(diaries);
    final first = sorted.first.date;
    final last = sorted.last.date;

    if (first.year == last.year && first.month == last.month) {
      return "${first.year}年${first.month}月の日記";
    }
    if (first.year == last.year) {
      return "${first.year}年${first.month}月〜${last.month}月の日記";
    }
    return "${first.year}年${first.month}月〜${last.year}年${last.month}月の日記";
  }
}
