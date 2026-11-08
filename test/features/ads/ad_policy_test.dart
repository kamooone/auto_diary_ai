import 'package:auto_diary_ai/features/ads/domain/ad_gateway.dart';
import 'package:auto_diary_ai/features/ads/domain/ad_policy.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeAdGateway implements AdGateway {
  RewardedResult rewarded = RewardedResult.earned;
  bool throws = false;

  int interstitialCount = 0;
  int rewardedCount = 0;

  @override
  Future<void> start() async {}

  @override
  Future<void> showInterstitial() async {
    interstitialCount++;
    if (throws) throw StateError('failed');
  }

  @override
  Future<RewardedResult> showRewarded() async {
    rewardedCount++;
    if (throws) throw StateError('failed');
    return rewarded;
  }
}

void main() {
  late FakeAdGateway gateway;

  setUp(() => gateway = FakeAdGateway());

  group('地図を表示する直前', () {
    test('インタースティシャル広告を表示する', () async {
      await AdPolicy(gateway: gateway, enabled: true).beforeMap();

      expect(gateway.interstitialCount, 1);
    });

    test('広告の表示に失敗しても、先へ進める', () async {
      gateway.throws = true;

      await AdPolicy(gateway: gateway, enabled: true).beforeMap();

      expect(gateway.interstitialCount, 1);
    });

    test('広告を表示しない設定のときは、広告を出さない', () async {
      await AdPolicy(gateway: gateway, enabled: false).beforeMap();

      expect(gateway.interstitialCount, 0);
    });
  });

  group('AIに日記を書いてもらう前', () {
    test('リワード広告を最後まで見たら、先へ進める', () async {
      final allowed =
          await AdPolicy(gateway: gateway, enabled: true).beforeGenerate();

      expect(allowed, isTrue);
      expect(gateway.rewardedCount, 1);
    });

    test('報酬を得る前に広告を閉じたら、先へ進めない', () async {
      gateway.rewarded = RewardedResult.dismissed;

      final allowed =
          await AdPolicy(gateway: gateway, enabled: true).beforeGenerate();

      expect(allowed, isFalse);
    });

    test('広告を用意できなかった場合は、広告のせいで書けなくならないよう先へ進める', () async {
      gateway.rewarded = RewardedResult.unavailable;

      final allowed =
          await AdPolicy(gateway: gateway, enabled: true).beforeGenerate();

      expect(allowed, isTrue);
    });

    test('広告の表示で例外になっても、先へ進める', () async {
      gateway.throws = true;

      final allowed =
          await AdPolicy(gateway: gateway, enabled: true).beforeGenerate();

      expect(allowed, isTrue);
    });

    test('広告を表示しない設定のときは、広告を出さずに先へ進める', () async {
      final allowed =
          await AdPolicy(gateway: gateway, enabled: false).beforeGenerate();

      expect(allowed, isTrue);
      expect(gateway.rewardedCount, 0);
    });
  });
}
