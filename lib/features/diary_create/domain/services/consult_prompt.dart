import '../../../diary/domain/entities/diary.dart';
import 'summary_text.dart';

/// 相談の途中の発言
class ConsultMessage {
  const ConsultMessage({
    required this.fromUser,
    required this.text,
    this.proposal,
  });

  final bool fromUser;
  final String text;

  /// AIが提案した書き方の指示(「自分で指定」にそのまま入れられる文章)
  final String? proposal;
}

/// 「日記を1つにする」の書き方を、AIに相談するときの指示文
class ConsultPrompt {
  const ConsultPrompt._();

  static const answerMarker = "【相談の回答】";
  static const proposalMarker = "【書き方の指示】";
  static const briefMarker = "【材料メモ】";

  static String first(List<Diary> diaries) {
    return """
$_role

ユーザーが選んだ${diaries.length}件の日記です(日付の古い順)。
$_task

最初に、日記を読んで、材料の特徴(テーマの幅、出来事の種類、繰り返しの多さ、全体の量など)を2〜4文で伝えてから、おすすめの書き方を提案してください。

$_format
$briefMarker
(これからの相談で、日記の全文の代わりに使う、材料の分析メモ。テーマ、出来事の種類、繰り返し、特徴、期間、件数を、500文字以内で書く)

日記
${SummaryText.format(diaries)}
""";
  }

  static String followUp({
    required String brief,
    required List<ConsultMessage> history,
    required String message,
  }) {
    final talk = history.map((e) {
      final proposal = e.proposal == null ? "" : "\n(提案した書き方の指示: ${e.proposal})";
      return "${e.fromUser ? "ユーザー" : "あなた"}: ${e.text}$proposal";
    }).join("\n");

    return """
$_role

$_task

材料の分析メモ(最初に日記を読んで作ったものです。日記の全文は、もう渡しません)
$brief

ここまでの相談
$talk

ユーザーの新しい発言
$message

ユーザーの発言に答えてください。書き方の提案を変える、または新しく出すときは、$proposalMarker も書いてください。質問に答えるだけのときは、$proposalMarker は書かないでください。

$_format
""";
  }

  static const _role = """
あなたは、日記アプリの「日記を1つにする」機能の、書き方の相談役です。
この機能は、ユーザーが選んだ作成済みの日記を材料に、別のAIが1つの日記を書きます。書き方は、次の5つから選べます。
1. 読み物(ブログ風): テーマごとに章立てして、細部を残しながら読み物にする
2. 時系列の記録: 日付順に、日ごとの出来事を省略せずに書く(長くなる)
3. 短い振り返り: 流れと印象に残った出来事だけを、短くまとめる
4. 出来事の一覧: 日付ごとの出来事を、箇条書きで並べる
5. 自分で指定: 書き方を文章で指示する""";

  static const _task = """
ユーザーの相談に乗って、材料に合った書き方を提案してください。
・日記の書き方の相談以外には、答えません。関係のない話には、その旨を短く伝えて、書き方の相談に戻してください。
・日記にないことを書き足すことはできません。写真や画像は扱えません。
・提案する書き方の指示は、あとで別のAIに、そのまま渡す文章です。「自分で指定」の欄にそのまま入れられるように、具体的に書いてください(形、章立ての有無、長さ、口調、残したい内容など。1〜5文)。
・やさしい言葉で、短く答えてください。""";

  static const _format = """
回答は必ず次の形式で書いてください。
$answerMarker
(ユーザーに見せる文章)
$proposalMarker
(提案する書き方の指示だけを書く。説明や前置きは書かない。提案しないときは、この見出しごと書かない)""";
}
