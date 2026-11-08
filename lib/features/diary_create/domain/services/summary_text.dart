import '../../../diary/domain/entities/diary.dart';

/// まとめ日記の材料にする、作成済みの日記を、AIに渡す文章にする
class SummaryText {
  const SummaryText._();

  /// 選べる日記の文字数(日付・タイトル・本文の合計)の上限。
  /// 365件×500文字(約18万文字)の約3倍。超えると、通信のサイズ上限に近づく
  static const maxChars = 600000;

  /// まとめるには、2件以上の日記が必要
  static const minCount = 2;

  /// 日付の古い順に、日付・タイトル・本文を並べる
  /// (同じ日付の日記は、作成した順)
  static String format(List<Diary> diaries) {
    return sorted(diaries).map(_one).join("\n\n");
  }

  /// AIに渡すときの形。日記の区切りをはっきりさせるため、日付の前に「■」を付ける
  /// (長い入力で、日記の日付と内容を取り違えないようにするため)
  static String formatForAi(List<Diary> diaries) {
    return sorted(diaries).map((e) => "■${_one(e)}").join("\n\n");
  }

  static List<Diary> sorted(List<Diary> diaries) {
    return [...diaries]..sort((a, b) {
      final byDate = a.date.compareTo(b.date);
      return byDate != 0 ? byDate : a.createdAt.compareTo(b.createdAt);
    });
  }

  /// 選んだ日記の文字数(上限と比べるのに使う)
  static int length(List<Diary> diaries) => format(diaries).length;

  static String _one(Diary diary) {
    final date = diary.date;
    final title = diary.title.trim();

    return "${date.year}年${date.month}月${date.day}日"
        "${title.isEmpty ? "" : " $title"}\n${diary.content.trim()}";
  }
}
