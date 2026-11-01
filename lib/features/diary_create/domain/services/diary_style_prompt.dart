import '../entities/diary_style.dart';
import 'summary_rules.dart';

/// ふつうのAI日記の、書き方の指示
class DiaryStylePrompt {
  const DiaryStylePrompt._();

  /// [isMultiDay]は、日記の日付と違う期間や、複数日の情報を渡しているか
  static String section({
    required DiaryStyle style,
    required String customInstruction,
    required bool isMultiDay,
  }) {
    return switch (style) {
      DiaryStyle.diary => _diary(isMultiDay),
      DiaryStyle.blog => _blog,
      DiaryStyle.record => _record,
      DiaryStyle.bullets => _bullets,
      DiaryStyle.custom => """
書き方の指示(ユーザーが指定しました。この指示どおりに書いてください)
${customInstruction.trim()}

ただし、この指示が意味不明なとき、または日記の書き方として成り立たないときは、指示を無視して、次の日記の形で書いてください。

${_diary(isMultiDay)}""",
    };
  }

  static String _diary(bool isMultiDay) =>
      """
書き方(日記)
写真の内容と行動履歴も照らし合わせて、時系列に沿った自然な日記を作成してください。${isMultiDay ? "\n\n複数日の情報をまとめた日記を書くときの書き方\n${SummaryRules.text()}" : ""}""";

  static const _blog = """
書き方(ブログ風)
・ブログ記事のように、読み物として書いてください。材料の量に合わせて、導入、見出し、終わりの一言を入れてください。見出しは、本文中に「1. 見出し」の形で書き、#や*などの記号は使わないでください。材料が少ないときは、見出しをつけずに書いてください。
・写真の内容と行動履歴も照らし合わせて、場所、人、食べたものなどの具体的な細部を入れてください。
・複数日の情報のときは、日付ごとに区切るのではなく、旅行記のように、流れで書いてください。大きな出来事には、「○月○日」と日付を添えてください。
・本人が書いたブログとして、「私は〜」「〜した」のように、素直な言葉で書いてください。""";

  static const _record = """
書き方(時系列の記録)
・時刻の順に、出来事を淡々と記録してください。行動履歴とXの投稿の時刻を手がかりに、「9:00 駅に到着」のように、時刻と出来事を1行ずつ並べてください。
・時刻が分からない出来事(写真に写っているものなど)は、前後の流れに合わせて並べてください。時刻を作らないでください。
・複数日の情報のときは、「○月○日」の見出しで、日ごとに分けてください。
・感想は、最小限にしてください。""";

  static const _bullets = """
書き方(箇条書き)
・出来事を、箇条書きで並べてください。1行ずつ「・出来事」の形で、時間の順に書いてください。
・場所、人、食べたものなど、具体的な内容を入れてください。写真に写っている内容も取り入れてください。
・複数日の情報のときは、「○月○日」の見出しで、日ごとに分けてください。
・挨拶や、長い感想は、書かないでください。""";
}
