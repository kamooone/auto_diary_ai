import 'dart:math' as math;

/// 日記を作っている間に見せる、ダウンロードのようなゲージの進み具合
///
/// AIは、途中までできた分を教えてくれないので、本当の進み具合は分からない。
/// 見積もった所要時間に合わせて進め、その時間を過ぎても、100%にはせずに、
/// 少しずつ進んで、終わりに近づいたように見せる(終わると画面が切り替わる)。
class GenerationGauge {
  const GenerationGauge._();

  /// 見積もった所要時間の、最短(短すぎると、ゲージが一瞬で進んでしまう)
  static const minExpectedSeconds = 5;

  /// 見積もった所要時間までに進める割合
  static const _atExpected = 0.9;

  /// 所要時間を過ぎたあと、最大でここまで進める
  static const _limit = 0.99;

  /// [elapsedSeconds]は経過時間、[expectedSeconds]は見積もった所要時間。0〜1を返す
  static double fraction(double elapsedSeconds, int expectedSeconds) {
    if (elapsedSeconds <= 0) return 0;

    final expected = math.max(expectedSeconds, minExpectedSeconds).toDouble();

    if (elapsedSeconds <= expected) {
      return _atExpected * elapsedSeconds / expected;
    }

    // 過ぎたあとは、だんだんゆっくり進む
    final over = elapsedSeconds - expected;
    final slow = math.max(expected * 0.5, 10);

    return _atExpected + (_limit - _atExpected) * (1 - math.exp(-over / slow));
  }

  /// 見積もった所要時間を過ぎたか
  static bool isOverExpected(double elapsedSeconds, int expectedSeconds) {
    return elapsedSeconds > math.max(expectedSeconds, minExpectedSeconds);
  }
}
