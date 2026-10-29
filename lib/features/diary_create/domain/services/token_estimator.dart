import '../../../location/domain/entities/timeline_item.dart';
import '../../../share/domain/entities/shared_post.dart';
import 'timeline_text.dart';

/// AIに日記を書いてもらうときに使うトークン数の、目安を求める
///
/// 正確な値は、AIが答えたあとにしか分からない。ここでの値は、足りないかもしれないことを
/// 送る前に知らせるためのもの(本当の上限は、サーバーが守る)。
/// 実際は足りるのに、見積もりの段階で「足りない」と出て使えなくなることを避けたいため、
/// **少なめ**に見積もる。多少の超過は認めて、枠を使い切ってから使えなくする。
///
/// 係数は、実機で測った値(2026-10-29、gemini-flash-lite)から決めた。
/// docs/token_estimation_test_cases.md に、測った結果を残してある。定期的に見直す。
class TokenEstimator {
  const TokenEstimator._();

  // 指示文(日付・形式の指定など、毎回同じ部分)。実測は約210
  static const instructionTokens = 210;

  // メモの1文字あたり。実測は約0.55(10,000文字で0.61)
  static const noteTokensPerChar = 0.55;

  // 行動履歴・Xの投稿の1文字あたり。日時や数字を含むため、メモより多い。実測は約0.7
  static const tokensPerChar = 0.7;

  // 写真1枚あたり(画像だけを送る)。サイズ・種類・枚数に関係なく一定で、実測は約1,085〜1,125
  static const tokensPerPhoto = 1050;

  // 日記の本文とタイトル。実測は、写真なしで60〜600、写真ありで130〜300。
  // AIが考える分(0〜800でばらつく)は含めない
  static const outputTokens = 200;

  /// [multiplier]は、AIの種類による消費量の倍率(サーバーが決める。通常は1)
  static int estimate({
    required String note,
    required List<TimelineItem> timeline,
    required List<SharedPost> posts,
    required int photoCount,
    double multiplier = 1,
  }) {
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
        outputTokens;

    return (tokens * multiplier).ceil();
  }

  // 投稿の日時の長さ(「2026-01-01 09:00:00.000」)
  static const _dateLength = 23;
}
