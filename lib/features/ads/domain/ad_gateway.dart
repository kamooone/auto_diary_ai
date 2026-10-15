/// リワード広告の結果
enum RewardedResult {
  /// 最後まで見て、報酬を得た
  earned,

  /// 広告を用意できなかった(通信できない、表示できる広告がないなど)
  unavailable,

  /// 報酬を得る前に閉じた
  dismissed,
}

/// 広告の表示(AdMobなど、広告の提供元に依存する部分)
abstract class AdGateway {
  /// 広告を使えるように準備する
  Future<void> start();

  /// インタースティシャル広告を表示し、閉じられるまで待つ
  /// 広告を用意できていない場合は、待たずに何もしない
  Future<void> showInterstitial();

  /// リワード広告を表示し、閉じられるまで待つ
  Future<RewardedResult> showRewarded();
}

/// 広告を表示しない(広告を使えない環境や、テスト用)
class NoAdGateway implements AdGateway {
  @override
  Future<void> start() async {}

  @override
  Future<void> showInterstitial() async {}

  @override
  Future<RewardedResult> showRewarded() async => RewardedResult.unavailable;
}
