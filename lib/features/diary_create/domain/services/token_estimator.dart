import 'dart:math' as math;

import '../../../ai/domain/entities/ai_model.dart';
import '../../../diary/domain/entities/diary.dart';
import '../../../location/domain/entities/timeline_item.dart';
import '../../../memo/domain/entities/memo.dart';
import '../../../memo/domain/services/memo_text.dart';
import '../../../share/domain/entities/shared_post.dart';
import '../entities/photo.dart';
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
    postsBaseTokens: postsBaseTokens,
    postsSlopeTokensPerChar: postsSlopeTokensPerChar,
    timelineTokensPerChar: timelineTokensPerChar,
    timelineBaseTokens: timelineBaseTokens,
    timelineSlopeTokensPerChar: timelineSlopeTokensPerChar,
    tokensPerPhoto: tokensPerPhoto,
    photoTimeTokens: photoTimeTokens,
    plainOutput: outputTokens,
    noteOutputTokensPerChar: noteOutputTokensPerChar,
    noteOutputCap: noteOutputCap,
    outputTokensPerChar: 0.35,
    // 日記を1つにするときの、日記1文字あたり(メモの係数とは別)
    diaryTokensPerChar: summaryDiaryTokensPerChar,
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

  // GPT(gpt-5-mini)。**Geminiの係数に、材料ごとの倍率をかけた値**にした(2026-11-26、ユーザー指示)。
  // GPTのテストをして、微調整する。以前のGPTの係数(2026-11-04〜11の実測。写真は縦横から計算など)は、
  // gitの履歴にある。
  //  ・文字(指示文・メモ): GPTのほうが多い。実測は、指示文417(Gemini 339)、メモ約0.83/文字(Gemini 約0.57)
  //    で、約1.3〜1.5倍。**×1.3**(指示文351・メモ0.6)
  //  ・写真: GPTのほうが少ない。1枚あたり約690(Geminiは約1,100)。**×0.6**(528)。
  //    Geminiと同じにすると、見積もりが実測を超える
  //  ・行動履歴・Xの投稿・ひとことメモ: GPTは、数字を数桁まとめて数えるので、Geminiと違う可能性がある。
  //    測るまでは、Geminiと同じ
  //  ・考える分(reasoning): 考える量は **low** にした(2026-11-26)。何も選ばない・メモだけは128、
  //    写真ありは256(G1・G2・G3)。最小の128の約8割、**+100**を足す。
  //    (medium のときは、毎回450〜580で+400だったが、low にしたら、G1の見積もりが実測を超えた)
  //    行動履歴などで、思考がもっと増える分は、足さない(少なめに外れるのは許容)
  // 日記を1つにする(まとめ)と、書き方の相談の係数と、作業時間の見積もり(ゲージ)は、
  // GPTの以前の値のまま(ゲージの長さの実測(31件で25秒など)と結びついているため)
  static const _gpt = _Coefficients(
    instruction: 351,
    noteTokensPerChar: 0.6,
    tokensPerChar: tokensPerChar * gptPostsRatio,
    postsBaseTokens: postsBaseTokens * gptPostsRatio,
    postsSlopeTokensPerChar: postsSlopeTokensPerChar * gptPostsRatio,
    timelineTokensPerChar: timelineTokensPerChar,
    timelineBaseTokens: timelineBaseTokens,
    timelineSlopeTokensPerChar: timelineSlopeTokensPerChar,
    tokensPerPhoto: 528,
    photoTimeTokens: photoTimeTokens,
    reasoningTokens: 100,
    plainOutput: outputTokens,
    noteOutputTokensPerChar: noteOutputTokensPerChar,
    noteOutputCap: noteOutputCap,
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

  // 写真1枚ごとに、画像と、撮影日時の行(「1枚目: 2026年1月1日 09:30」)を送る。
  // 写真の縦横で、トークンが変わるAI(GPT)の、縦横からの計算は、いったん、やめた
  // (2026-11-26。Geminiと同じ、1枚あたり一定。以前の計算は、gitの履歴にある)
  static int _photoInputTokens(_Coefficients c, int photoCount) {
    return photoCount * (c.tokensPerPhoto + c.photoTimeTokens);
  }

  // Geminiの、ふつうのAI日記の係数は、すべて、実測の約80%にそろえる(2026-11-25)。
  // 固定の分と、1つあたりの分で、割合が違うと、写真やメモが増えるほど、見積もり÷実測が
  // 変わってしまう(固定の分だけ低く、1つあたりの分だけ高いと、増えるほど100%に近づく)。
  // 実測の、約80%にそろえると、量が少なくても多くても、見積もり÷実測が、約75〜83%になる。
  // 思考(0〜544でばらつく)は含めない。

  // 指示文(日付・形式の指定など、毎回同じ部分)。実測は約340(何も選ばない状態の入力)。
  // 以前の約210〜265から、プロンプトが長くなった
  static const instructionTokens = 270;

  // メモの1文字あたり。実測は約0.55〜0.58(969文字と9,366文字)
  static const noteTokensPerChar = 0.46;

  // メモがあるときの、日記の出力の増え方。AIが、メモをなぞって日記にするため、出力がメモに応じて増える。
  // 実測: 969文字で出力576、9,366文字で441(メモが長いと、まとめるので増えない)
  static const noteOutputTokensPerChar = 0.4;
  static const noteOutputCap = 350;

  // Xの投稿・ひとことメモは、「一定の分 + 文字数に比例する分」で増える(2026-11-25の最終テスト)。
  // 実測(投稿だけ)は、10件(約1,204文字)で1,190、50件(約6,164文字)で4,750。
  // この2点は、「約326 + 0.718 × 文字数」の直線に乗る。その約80%にそろえて、260 + 0.57 × 文字数。
  // 文字数が少ないとき(約1,130文字未満)は、1文字あたり[tokensPerChar](10件の実測約0.99の約80%)
  // を上限にする。ひとことメモは、まだ測っていないので、投稿と同じ式で数える
  static const tokensPerChar = 0.8;
  static const postsBaseTokens = 260.0;
  static const postsSlopeTokensPerChar = 0.57;

  // GPTは、Xの投稿の文字を、Geminiより細かく数える。Geminiの式のままだと、入力の見積もりが実測の約97%
  // (100件6,676に対し約6,440、300件19,566に対し約19,050)で、上限に近い。×0.85にして、約70〜83%にする
  // (2026-11-26のG5)。ひとことメモも、同じ式で数えるので、同じ倍率になる
  static const gptPostsRatio = 0.85;

  /// Xの投稿・ひとことメモの文章([chars]文字)のトークンの目安
  static double postsTokens(int chars, {AiModel model = AiModel.gemini}) {
    final c = _of(model);

    final base = c.postsBaseTokens;
    final slope = c.postsSlopeTokensPerChar;
    if (base == null || slope == null || chars <= 0) {
      return chars * c.tokensPerChar;
    }

    return math.min(chars * c.tokensPerChar, base + slope * chars);
  }

  // 行動履歴は、「一定の分 + 文字数に比例する分」で増える(2026-11-25の最終テスト)。
  // 実測は、10件(約270文字)で540、100件(約3,043文字)で2,829、500件(約15,100文字)で12,804。
  // この3点は、「約317 + 0.825 × 文字数」の直線に、誤差30以内で乗る(1文字あたりは、文字数が増えると、
  // 約2.0 → 0.93 → 0.85と下がり、0.825に近づく)。その約80%にそろえて、250 + 0.66 × 文字数。
  // 文字数が少ないとき(約266文字未満)は、この式だと、少ない履歴(1件など)で多くなりすぎるので、
  // 1文字あたり[timelineTokensPerChar](10件の実測の約80%)を上限にする。
  // (割合の式 9.4 × 文字数^0.68 は、500件で下がりすぎて、実測の51%になったので、やめた)
  static const timelineTokensPerChar = 1.6;
  static const timelineBaseTokens = 250.0;
  static const timelineSlopeTokensPerChar = 0.66;

  /// 行動履歴の文章([chars]文字)のトークンの目安
  static double timelineTokens(int chars, {AiModel model = AiModel.gemini}) {
    final c = _of(model);
    final perChar = c.timelineTokensPerChar ?? c.tokensPerChar;

    final base = c.timelineBaseTokens;
    final slope = c.timelineSlopeTokensPerChar;
    if (base == null || slope == null || chars <= 0) return chars * perChar;

    return math.min(chars * perChar, base + slope * chars);
  }

  // 写真1枚あたり(画像だけを送る)。サイズ・種類・枚数に関係なく一定で、実測は約1,085〜1,125
  static const tokensPerPhoto = 880;

  // 日記を1つにするときの、日記1文字あたり。実測(2026-11-25、日記5件と25件)は、
  // 5件(約2,579文字)で入力2,240、25件(約9,140文字)で入力7,335。傾きは約0.78/文字で、
  // 切片は約236(まとめの指示文の分)。その約80%にそろえて、0.62
  static const summaryDiaryTokensPerChar = 0.62;

  // 写真ごとに送る、撮影日時の行(「1枚目: 2026年1月1日 09:30」。約20文字で、数字が多い)の分。
  // 約28トークンの約80%。2026-11-25に、撮影日時を送るようにした。最終テストで、測り直す
  static const photoTimeTokens = 22;

  // 日記の本文とタイトル。実測は、何も選ばないとき約50、写真ありで55〜156。
  // 最小に近い値にする。AIが考える分(0〜800でばらつく)は含めない
  static const outputTokens = 40;

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
      SummaryStyle.reading ||
      SummaryStyle.custom => math.min((chars * c.readingRatio).round(), 5000),
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
        c.consultOutput +
        c.reasoningTokens;

    return (tokens * multiplier).ceil();
  }

  /// [diaries]は、まとめ日記の材料にする作成済みの日記(写真・投稿・履歴とは同時に選ばない)
  /// [multiplier]は、AIの種類による消費量の倍率(サーバーが決める。通常は1)
  static int estimate({
    required String note,
    required List<TimelineItem> timeline,
    Set<TimelineItem> timelineAddressStays = const {},
    required List<SharedPost> posts,
    List<Memo> memos = const [],
    required int photoCount,
    List<Photo> photos = const [],
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
      timelineAddressStays: timelineAddressStays,
      posts: posts,
      memos: memos,
      photoCount: photoCount,
      photos: photos,
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
    Set<TimelineItem> timelineAddressStays = const {},
    required List<SharedPost> posts,
    List<Memo> memos = const [],
    required int photoCount,
    List<Photo> photos = const [],
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
      timelineAddressStays: timelineAddressStays,
      posts: posts,
      memos: memos,
      photoCount: photoCount,
      photos: photos,
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
    required Set<TimelineItem> timelineAddressStays,
    required List<SharedPost> posts,
    required List<Memo> memos,
    required int photoCount,
    required List<Photo> photos,
    required List<Diary> diaries,
    required SummaryStyle summaryStyle,
    required AiModel model,
    required int lengthChars,
  }) {
    final c = _of(model);

    final timelineChars = TimelineText.format(
      timeline,
      addressStays: timelineAddressStays,
    ).length;

    final chars =
        MemoText.format(memos).length +
        posts.fold<int>(
          0,
          (sum, e) => sum + e.text.length + e.url.length + _dateLength,
        );

    final input =
        c.instruction +
        note.length * c.noteTokensPerChar +
        timelineTokens(timelineChars, model: model) +
        postsTokens(chars, model: model) +
        _photoInputTokens(c, photoCount) +
        SummaryText.length(diaries) * c.diaryTokensPerChar;

    final noteOutput = math.min(
      (note.length * c.noteOutputTokensPerChar).round(),
      c.noteOutputCap,
    );

    final output = diaries.isEmpty
        ? math.max(
            c.plainOutput + noteOutput,
            (lengthChars * c.outputTokensPerChar).round(),
          )
        : summaryOutputTokens(
            summaryStyle,
            diaries,
            model: model,
            lengthChars: lengthChars,
          );

    // 考える分(GPTは、ほぼ必ず出る)も、最低限の量は、足す
    return (input: input, output: output + c.reasoningTokens);
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
    this.postsBaseTokens,
    this.postsSlopeTokensPerChar,
    this.timelineTokensPerChar,
    this.timelineBaseTokens,
    this.timelineSlopeTokensPerChar,
    required this.tokensPerPhoto,
    this.photoTimeTokens = 0,
    this.reasoningTokens = 0,
    required this.plainOutput,
    this.noteOutputTokensPerChar = 0,
    this.noteOutputCap = 0,
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

  /// Xの投稿・ひとことメモの、文字数によるトークンの式(一定の分 + 文字数 × 1文字あたり)。nullなら、1文字あたり一定
  final double? postsBaseTokens;
  final double? postsSlopeTokensPerChar;

  /// 行動履歴だけの、1文字あたりのトークン(nullなら、tokensPerCharと同じ)
  final double? timelineTokensPerChar;

  /// 行動履歴の、文字数によるトークンの式(一定の分 + 文字数 × 1文字あたり)。nullなら、1文字あたり一定
  final double? timelineBaseTokens;
  final double? timelineSlopeTokensPerChar;
  final int tokensPerPhoto;

  /// 写真1枚ごとに送る、撮影日時の行のトークン
  final int photoTimeTokens;

  /// AIが考える分(reasoning)の、最低限の量。毎回出るAI(GPT)だけ、足す
  final int reasoningTokens;

  /// メモがあるときに、ふつうのAI日記の出力へ加える、1文字あたりのトークンと上限
  final double noteOutputTokensPerChar;
  final int noteOutputCap;

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
