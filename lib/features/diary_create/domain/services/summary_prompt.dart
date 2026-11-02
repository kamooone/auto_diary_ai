import '../../../diary/domain/entities/diary.dart';
import '../entities/summary_style.dart';
import 'summary_text.dart';

/// 作成済みの日記を1つの日記にするときの、AIへの指示文
class SummaryPrompt {
  const SummaryPrompt._();

  static String build({
    required SummaryStyle style,
    required List<Diary> diaries,
    required String note,
    String customInstruction = '',
  }) {
    final chars = SummaryText.length(diaries);

    return """
あなたは、日記を書いた本人になりきって文章を書くAIです。

以下は、ユーザー本人が書いた${diaries.length}件の日記です(日付の古い順)。
これらを材料に、この期間を1つの日記にした文章を書いてください。あわせて、その内容に合ったタイトルも書いてください。

${_style(style, chars, customInstruction)}

共通のルール
・元の日記にない出来事、気持ち、感想は、付け足さないでください。
・全体を振り返る感想や、「充実した日々だった」のような決まり文句は、書かないでください。
・下の「ユーザーが追加で伝えたいこと」があれば、形や長さも含めて、それを最優先してください。

ユーザーが追加で伝えたいこと
${note.trim().isEmpty ? "(なし)" : note.trim()}

日記
${SummaryText.format(diaries)}

回答は必ず次の形式で書いてください。前置きや説明、記号による装飾は付けないでください。

タイトル: (日記のタイトルを1行で)
本文:
(日記の本文)
""";
  }

  static String _style(SummaryStyle style, int chars, String custom) {
    return switch (style) {
      SummaryStyle.reading => _reading(chars),
      // 日記を連結させるは、AIを使わずにつなげる(SummaryJoin)ので、ここには来ない。念のため読み物にする
      SummaryStyle.chronicle => _reading(chars),
      SummaryStyle.brief => _brief(chars),
      SummaryStyle.list => _list,
      SummaryStyle.custom => """
書き方の指示(ユーザーが指定しました。この指示どおりに書いてください)
${custom.trim()}

ただし、この指示が意味不明なとき、または日記を1つにする文章の書き方として成り立たないときは、指示を無視して、次の読み物の形で書いてください。

${_reading(chars)}""",
    };
  }

  static String _reading(int chars) => """
形(読み物)
材料を読んで、読み物として一番読みやすい形を判断してください。
・5件以下のとき、または似た出来事の繰り返しが中心で内容に幅がないときは、章立てにせず、日付の流れに沿った1本の文章にしてください。繰り返しは、「何度も」「ほぼ毎日」のように頻度でまとめてください。
・仕事、旅行、趣味、人付き合いなど、性格の違う出来事が混ざっているときは、テーマごとの章立てにしてください。章は、内容から自然に分かれる2〜6個にして、無理に作らないでください。章の見出しは、本文中に「1. 見出し」の形で書き、#や*などの記号は使わないでください。
・章立てにしても、章の中は時間の流れに沿って書いてください。

書き方
・本人が書いた日記として、「私は〜」「〜した」のように、素直な言葉で書いてください。元の日記の口調や言い回しも引き継いでください。
・要約しすぎないでください。場所、人、食べたもの、したこと、気持ちなどの具体的な細部を、できるだけ残してください。大きな出来事には、「○月○日」と日付を添えてください。
・同じことの繰り返しだけは、まとめてかまいません。
・長さの目安は${SummaryText.lengthGuide(chars)}です。""";

  static String _brief(int chars) => """
形(読み物・簡単なログ風)
読み物を、もっと簡潔にした形です。
・印象に残った出来事を選んで、いつの出来事か分かるように、「○月○日」と日付を添えて書いてください。日付が一日に決められない出来事(何度もあったこと)は、「1月上旬」「毎週のように」のように、時期や頻度で示してください。
・時間の流れに沿って、いくつかの段落に分けてください。1つの段落は、2〜4文にして、段落と段落の間は、1行空けてください。見出しは付けないでください。
・細かい出来事や、同じことの繰り返しは省いてかまいません。
・本人が書いた日記として、「私は〜」「〜した」のように、素直な言葉で書いてください。
・長さの目安は${SummaryText.lengthGuide(chars, lowRatio: 0.03, highRatio: 0.05, minLow: 200, maxLow: 1000, maxHigh: 1500)}です。""";

  static const _list = """
形(出来事の一覧)
・文章ではなく、出来事の一覧にしてください。1つの日記につき、主な出来事を1〜2行にまとめて、日付の古い順に並べてください。
・1行ずつ「・○月○日 出来事」の形で書いてください。場所、人、食べたものなど、具体的な内容を入れてください。
・章の見出し、挨拶、感想は、書かないでください。""";
}
