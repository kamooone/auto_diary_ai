import 'dart:math' as math;

import '../../../ai/domain/entities/ai_model.dart';
import '../../../diary/domain/entities/diary.dart';
import '../../../location/domain/entities/timeline_item.dart';
import '../../../memo/domain/entities/memo.dart';
import '../../../memo/domain/services/memo_text.dart';
import '../../../share/domain/entities/shared_post.dart';
import '../entities/summary_style.dart';
import 'summary_text.dart';
import 'timeline_text.dart';

/// AIに日記を書いてもらうときに使うトークン数の、目安を求める
///
/// 正確な値は、AIが答えたあとにしか分からない。ここでの値は、足りないかもしれないことを
/// 送る前に知らせるためのもの(本当の上限は、サーバーが守る)。
/// 実際は足りるのに、見積もりの段階で「足りない」と出て使えなくなることを避けたいため、
/// **実際より少なく**見積もる(測ったどのケースでも、見積もり < 実際の消費になるようにする)。
/// 多少の超過は認めて、枠を使い切ってから使えなくする。
///
/// 係数は、実機で測った値(2026-10-29、gemini-flash-lite)から決めた。
/// docs/token_estimation_test_cases.md に、測った結果を残してある。定期的に見直す。
///
/// 係数は、AIの種類ごとに違う(GPTは、同じ日本語でも、Geminiより多くのトークンになる)。
/// Gemini: 実機で測った値から決めた。 GPT(gpt-5-mini): 2026-11-04〜05 の実測から決めた
/// (1月3件・31件、2・3・10月86件。出来事の一覧・簡単なブログ風・ブログ風・相談)。
/// GPTの、写真は実測済み(2026-11-05)。行動履歴・Xの投稿・メモは、まだ測っていない(要実測)
class TokenEstimator {
  const TokenEstimator._();

  static const _gemini = _Coefficients(
    instruction: instructionTokens,
    noteTokensPerChar: noteTokensPerChar,
    tokensPerChar: tokensPerChar,
    tokensPerPhoto: tokensPerPhoto,
    plainOutput: outputTokens,
    outputTokensPerChar: 0.35,
    diaryTokensPerChar: noteTokensPerChar,
    readingRatio: 0.08,
    briefRatio: 0.02,
    listBase: 0,
    listPerDiary: 15,
    consultFixed: consultFixedTokens,
    consultOutput: consultOutputTokens,
    baseSeconds: 3,
    secondsPerInputToken: 0.0002,
    outputTokensPerSecond: 500,
    listOutputTokensPerSecond: 500,
  );

  // GPT(gpt-5-mini)。写真は1枚約460(1枚と3枚の差から。写真は2〜8MBでも、
  // アプリが縮小して送るので、大きさによらず同じ)。指示文は固定で約480(3件の測定から)、
  // ふつうのAI日記の出力は、写真1枚で約130、3枚で約240。
  // 日記の入力は、固定が約500、1文字あたり約0.85(測った5点で、
  // 見積もり÷実測が84〜95%に収まる値にした。少なめにする方針は、Geminiと同じ)。
  // 出力は、出来事の一覧が1件約45〜100、簡単なブログ風が日記の約5.7%、
  // ブログ風が日記の8.7〜15%(読み物の長さの指示が、日記の量で変わる)
  static const _gpt = _Coefficients(
    instruction: 450,
    noteTokensPerChar: 0.82,
    tokensPerChar: 0.9,
    tokensPerPhoto: 450,
    plainOutput: 100,
    outputTokensPerChar: 0.5,
    diaryTokensPerChar: 0.82,
    readingRatio: 0.08,
    briefRatio: 0.045,
    listBase: 100,
    listPerDiary: 35,
    consultFixed: 900,
    consultOutput: 500,
    baseSeconds: 4.5,
    secondsPerInputToken: 0.00012,
    outputTokensPerSecond: 130,
    listOutputTokensPerSecond: 70,
  );

  static _Coefficients _of(AiModel model) => switch (model) {
    AiModel.gemini => _gemini,
    AiModel.gpt => _gpt,
  };

  /// AIの種類ごとの、写真1枚あたりのトークン
  static int photoTokens(AiModel model) => _of(model).tokensPerPhoto;

  // 指示文(日付・形式の指定など、毎回同じ部分)。実測は約210〜265
  static const instructionTokens = 200;

  // メモの1文字あたり。実測は約0.5〜0.6(10,000文字で0.61)
  static const noteTokensPerChar = 0.5;

  // 行動履歴・Xの投稿の1文字あたり。日時や数字を含むため、メモより多い。実測は約0.68〜0.73
  static const tokensPerChar = 0.65;

  // 写真1枚あたり(画像だけを送る)。サイズ・種類・枚数に関係なく一定で、実測は約1,085〜1,125
  static const tokensPerPhoto = 1050;

  // 日記の本文とタイトル。実測は、写真なしで60〜600、写真ありで130〜300。
  // 何も選ばないときの実測(280〜370)より少なくなるよう、最小に近い値にする。
  // AIが考える分(0〜800でばらつく)は含めない
  static const outputTokens = 50;

  // 日記を1つにするときの出力。書き方ごとに、書く長さが違うため、日記の量から少なめに見積もる(要実測)
  //  読み物(ブログ風): 日記の15〜25%の長さ(上限12,000文字) / 日記を連結させる: AIを使わない(0)(実測は日記1文字あたり約0.6)
  //  読み物(簡単なブログ風): 日記の3〜5%(上限1,500文字) / 出来事の一覧: 1件につき1〜2行
  static int summaryOutputTokens(
    SummaryStyle style,
    List<Diary> diaries, {
    AiModel model = AiModel.gemini,
    int lengthChars = 0,
  }) {
    final c = _of(model);
    final chars = SummaryText.length(diaries);

    // 文字数の目安を指定したときは、その長さで書くので、日記の量からの見積もりに代える
    if (lengthChars > 0 &&
        style != SummaryStyle.list &&
        style != SummaryStyle.chronicle) {
      return (lengthChars * c.outputTokensPerChar).round();
    }

    return switch (style) {
      SummaryStyle.reading || SummaryStyle.custom => math.min(
        (chars * c.readingRatio).round(),
        5000,
      ),
      // 日記を連結させるは、AIを使わない
      SummaryStyle.chronicle => 0,
      SummaryStyle.brief => math.min((chars * c.briefRatio).round(), 1000),
      SummaryStyle.list => c.listBase + diaries.length * c.listPerDiary,
    };
  }

  // 書き方の相談で、最初の送信(日記の全文を送る)に使うトークンの目安。
  // 指示文と、AIの回答(材料メモを含む)の分を含む
  static const consultFixedTokens = 500;
  static const consultOutputTokens = 300;

  static int estimateConsult(
    List<Diary> diaries, {
    double multiplier = 1,
    AiModel model = AiModel.gemini,
  }) {
    final c = _of(model);
    final tokens =
        c.consultFixed +
        SummaryText.length(diaries) * c.diaryTokensPerChar +
        c.consultOutput;

    return (tokens * multiplier).ceil();
  }

  /// [diaries]は、まとめ日記の材料にする作成済みの日記(写真・投稿・履歴とは同時に選ばない)
  /// [multiplier]は、AIの種類による消費量の倍率(サーバーが決める。通常は1)
  static int estimate({
    required String note,
    required List<TimelineItem> timeline,
    required List<SharedPost> posts,
    List<Memo> memos = const [],
    required int photoCount,
    List<Diary> diaries = const [],
    SummaryStyle summaryStyle = SummaryStyle.reading,
    double multiplier = 1,
    AiModel model = AiModel.gemini,
    int lengthChars = 0,
  }) {
    // 日記を連結させるは、AIを使わずにつなげるので、トークンを使わない
    if (diaries.isNotEmpty && summaryStyle == SummaryStyle.chronicle) return 0;

    final parts = _parts(
      note: note,
      timeline: timeline,
      posts: posts,
      memos: memos,
      photoCount: photoCount,
      diaries: diaries,
      summaryStyle: summaryStyle,
      model: model,
      lengthChars: lengthChars,
    );

    return ((parts.input + parts.output) * multiplier).ceil();
  }

  /// 作成が終わるまでにかかる時間(秒)の目安。作成中のゲージの長さに使う。
  /// 正確さは求めない(混雑や、AIが考える量で、大きく変わる)。
  /// 日記を連結させるは、AIを使わないので0
  static int estimateSeconds({
    required String note,
    required List<TimelineItem> timeline,
    required List<SharedPost> posts,
    List<Memo> memos = const [],
    required int photoCount,
    List<Diary> diaries = const [],
    SummaryStyle summaryStyle = SummaryStyle.reading,
    AiModel model = AiModel.gemini,
    int lengthChars = 0,
  }) {
    if (diaries.isNotEmpty && summaryStyle == SummaryStyle.chronicle) return 0;

    final c = _of(model);
    final parts = _parts(
      note: note,
      timeline: timeline,
      posts: posts,
      memos: memos,
      photoCount: photoCount,
      diaries: diaries,
      summaryStyle: summaryStyle,
      model: model,
      lengthChars: lengthChars,
    );

    final seconds =
        c.baseSeconds +
        parts.input * c.secondsPerInputToken +
        parts.output /
            (diaries.isNotEmpty && summaryStyle == SummaryStyle.list
                ? c.listOutputTokensPerSecond
                : c.outputTokensPerSecond);

    return seconds.ceil();
  }

  // 入力と出力のトークンの見積もり(消費量と時間の、どちらの見積もりにも使う)
  static ({double input, int output}) _parts({
    required String note,
    required List<TimelineItem> timeline,
    required List<SharedPost> posts,
    required List<Memo> memos,
    required int photoCount,
    required List<Diary> diaries,
    required SummaryStyle summaryStyle,
    required AiModel model,
    required int lengthChars,
  }) {
    final c = _of(model);

    final chars =
        TimelineText.format(timeline).length +
        MemoText.format(memos).length +
        posts.fold<int>(
          0,
          (sum, e) => sum + e.text.length + e.url.length + _dateLength,
        );

    final input =
        c.instruction +
        note.length * c.noteTokensPerChar +
        chars * c.tokensPerChar +
        photoCount * c.tokensPerPhoto +
        SummaryText.length(diaries) * c.diaryTokensPerChar;

    final output = diaries.isEmpty
        ? math.max(c.plainOutput, (lengthChars * c.outputTokensPerChar).round())
        : summaryOutputTokens(
            summaryStyle,
            diaries,
            model: model,
            lengthChars: lengthChars,
          );

    return (input: input, output: output);
  }

  // 投稿の日時の長さ(「2026-01-01 09:00:00.000」)
  static const _dateLength = 23;
}

/// AIの種類ごとの、見積もりの係数
class _Coefficients {
  const _Coefficients({
    required this.instruction,
    required this.noteTokensPerChar,
    required this.tokensPerChar,
    required this.tokensPerPhoto,
    required this.plainOutput,
    required this.outputTokensPerChar,
    required this.diaryTokensPerChar,
    required this.readingRatio,
    required this.briefRatio,
    required this.listBase,
    required this.listPerDiary,
    required this.consultFixed,
    required this.consultOutput,
    required this.baseSeconds,
    required this.secondsPerInputToken,
    required this.outputTokensPerSecond,
    required this.listOutputTokensPerSecond,
  });

  final int instruction;
  final double noteTokensPerChar;
  final double tokensPerChar;
  final int tokensPerPhoto;

  /// 日記を1つにする以外(ふつうのAI日記)の出力
  final int plainOutput;

  /// 文字数の目安を選んだときの、出力 = 目安の文字数 × この値
  /// (AIは目安どおりに書くとは限らず、短くなることも多いため、実際のトークンより少なめ。要実測)
  final double outputTokensPerChar;
  final double diaryTokensPerChar;

  /// 読み物・自分で指定の出力 = 日記の文字数 × この値
  final double readingRatio;

  /// 簡単なブログ風の出力 = 日記の文字数 × この値
  final double briefRatio;

  /// 出来事の一覧の出力 = [listBase] + 日記の件数 × [listPerDiary]
  final int listBase;
  final int listPerDiary;

  final int consultFixed;
  final int consultOutput;

  /// 作成にかかる時間の目安 = [baseSeconds] + 入力 × [secondsPerInputToken] + 出力 ÷ [outputTokensPerSecond]
  /// (出来事の一覧は、出力が遅いので[listOutputTokensPerSecond])。
  /// 作成中のゲージの長さに使う。見込みが実際より長いと、ゲージが途中で終わってしまうので、
  /// 実測に近い値にする(短めなら、最後にゆっくり進むだけで済む)。
  /// 実測(2026-11-05〜06、入力トークン / 出力トークン / 秒):
  ///  GPT: ブログ風 31,112 / 3,053 / 32、353件 188,148 / 3,701 / 56.4、出来事の一覧 11,728 / 1,383 / 25、
  ///       簡単なブログ風 31件 9.6、読み物 31件 20
  ///  Gemini(lite): 写真1枚 1,363 / 64 / 3.2、30件 8,685 / 1,141(思考込み) / 13.1、
  ///       120件 32,178 / 2,281 / 9.8、353件 134,869 / 4,349 / 31.5
  /// Geminiは同じ程度の入力でも、秒数のばらつきが大きい(30件が120件より遅かった)
  final double baseSeconds;
  final double secondsPerInputToken;
  final double outputTokensPerSecond;
  final double listOutputTokensPerSecond;
}
