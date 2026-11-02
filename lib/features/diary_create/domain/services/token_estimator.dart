import 'dart:math' as math;

import '../../../diary/domain/entities/diary.dart';
import '../../../location/domain/entities/timeline_item.dart';
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
class TokenEstimator {
  const TokenEstimator._();

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
  //  読み物: 日記の10〜15%の長さ(上限8,000文字) / 時系列の記録: 日記とほぼ同じ量(実測は日記1文字あたり約0.6)
  //  短い振り返り: 日記の3〜5%(上限1,500文字) / 出来事の一覧: 1件につき1〜2行
  static int summaryOutputTokens(SummaryStyle style, List<Diary> diaries) {
    final chars = SummaryText.length(diaries);

    return switch (style) {
      SummaryStyle.reading || SummaryStyle.custom => math.min(
        (chars * 0.05).round(),
        3000,
      ),
      // 時系列の記録は、AIを使わない
      SummaryStyle.chronicle => 0,
      SummaryStyle.brief => math.min((chars * 0.02).round(), 1000),
      SummaryStyle.list => diaries.length * 15,
    };
  }

  // 書き方の相談で、最初の送信(日記の全文を送る)に使うトークンの目安。
  // 指示文と、AIの回答(材料メモを含む)の分を含む
  static const consultFixedTokens = 500;
  static const consultOutputTokens = 300;

  static int estimateConsult(List<Diary> diaries, {double multiplier = 1}) {
    final tokens =
        consultFixedTokens +
        SummaryText.length(diaries) * noteTokensPerChar +
        consultOutputTokens;

    return (tokens * multiplier).ceil();
  }

  /// [diaries]は、まとめ日記の材料にする作成済みの日記(写真・投稿・履歴とは同時に選ばない)
  /// [multiplier]は、AIの種類による消費量の倍率(サーバーが決める。通常は1)
  static int estimate({
    required String note,
    required List<TimelineItem> timeline,
    required List<SharedPost> posts,
    required int photoCount,
    List<Diary> diaries = const [],
    SummaryStyle summaryStyle = SummaryStyle.reading,
    double multiplier = 1,
  }) {
    // 時系列の記録は、AIを使わずにつなげるので、トークンを使わない
    if (diaries.isNotEmpty && summaryStyle == SummaryStyle.chronicle) return 0;

    final chars =
        TimelineText.format(timeline).length +
        posts.fold<int>(
          0,
          (sum, e) => sum + e.text.length + e.url.length + _dateLength,
        );

    final tokens =
        instructionTokens +
        note.length * noteTokensPerChar +
        chars * tokensPerChar +
        photoCount * tokensPerPhoto +
        SummaryText.length(diaries) * noteTokensPerChar +
        (diaries.isEmpty
            ? outputTokens
            : summaryOutputTokens(summaryStyle, diaries));

    return (tokens * multiplier).ceil();
  }

  // 投稿の日時の長さ(「2026-01-01 09:00:00.000」)
  static const _dateLength = 23;
}
