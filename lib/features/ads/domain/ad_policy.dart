import 'ad_gateway.dart';

/// いつ広告を出すか、広告のあとに先へ進めるかを決める
class AdPolicy {
  final AdGateway gateway;

  /// 広告を表示するか(プランによって変えられるようにしておく)
  final bool enabled;

  const AdPolicy({required this.gateway, required this.enabled});

  /// 地図を表示する直前に、インタースティシャル広告を出す
  Future<void> beforeMap() async {
    if (!enabled) return;

    try {
      await gateway.showInterstitial();
    } catch (_) {
      // 広告の失敗で、地図を開けなくならないようにする
    }
  }

  /// AIに日記を書いてもらう前に、リワード広告を出す
  /// 先へ進んでよい場合はtrue
  ///
  /// 広告を用意できなかった場合は、広告のせいで日記を書けなくならないよう、先へ進める。
  /// 報酬を得る前に閉じた場合だけ、先へ進めない
  Future<bool> beforeGenerate() async {
    if (!enabled) return true;

    try {
      return await gateway.showRewarded() != RewardedResult.dismissed;
    } catch (_) {
      return true;
    }
  }
}
