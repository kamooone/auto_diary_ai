import '../../../location/domain/entities/timeline_item.dart';
import '../../../share/domain/entities/shared_post.dart';
import 'timeline_text.dart';

/// AIに日記を書いてもらうときに使うトークン数の、目安を求める
///
/// 正確な値は、AIが答えたあとにしか分からない。ここでの値は、足りないかもしれないことを
/// 送る前に知らせるためのもの(本当の上限は、サーバーが守る)。
/// 足りないと誤って断らないよう、**多めに**見積もる。
///
/// 係数は仮の値。実際に使った量を測って、決め直す。
/// (実測: 何も渡さない日記が313トークン)
class TokenEstimator {
  const TokenEstimator._();

  // 指示文(日付・形式の指定など、毎回同じ部分)
  static const instructionTokens = 300;

  // 日本語の文章の1文字あたり(日時や数字を含むため、1文字を1トークンとして多めに見る)
  static const tokensPerChar = 1.0;

  // 写真1枚あたり(画像と、撮影日時・場所の情報)
  static const tokensPerPhoto = 1200;

  // 日記の本文とタイトル、AIが考える分
  static const outputTokens = 1000;

  /// [multiplier]は、AIの種類による消費量の倍率(サーバーが決める。通常は1)
  static int estimate({
    required String note,
    required List<TimelineItem> timeline,
    required List<SharedPost> posts,
    required int photoCount,
    double multiplier = 1,
  }) {
    final chars =
        note.length +
        TimelineText.format(timeline).length +
        posts.fold<int>(
          0,
          (sum, e) => sum + e.text.length + e.url.length + _dateLength,
        );

    final tokens =
        instructionTokens +
        chars * tokensPerChar +
        photoCount * tokensPerPhoto +
        outputTokens;

    return (tokens * multiplier).ceil();
  }

  // 投稿の日時の長さ(「2026-01-01 09:00:00.000」)
  static const _dateLength = 23;
}
