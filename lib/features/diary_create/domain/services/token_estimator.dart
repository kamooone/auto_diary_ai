import '../../../location/domain/entities/timeline_item.dart';
import '../../../share/domain/entities/shared_post.dart';
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
