import 'dart:async';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../../../core/logging/app_log.dart';
import '../domain/ad_gateway.dart';
import 'ad_unit_ids.dart';

/// AdMobの広告を表示する
///
/// 表示するときに待たされないよう、広告はあらかじめ読み込んでおく
class AdMobAdGateway implements AdGateway {
  // 読み込み中の広告を待つ時間(これを過ぎたら、広告なしで先へ進む)
  static const _waitLoad = Duration(seconds: 3);

  Future<InterstitialAd?>? _interstitial;
  Future<RewardedAd?>? _rewarded;

  @override
  Future<void> start() async {
    await MobileAds.instance.initialize();
    AppLog.add('広告', 'AdMobを初期化しました');

    _interstitial = _loadInterstitial();
    _rewarded = _loadRewarded();
  }

  Future<InterstitialAd?> _loadInterstitial() {
    final completer = Completer<InterstitialAd?>();

    InterstitialAd.load(
      adUnitId: AdUnitIds.interstitial,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          AppLog.add('広告', 'インタースティシャル広告を読み込みました');
          completer.complete(ad);
        },
        onAdFailedToLoad: (error) {
          AppLog.add('広告', 'インタースティシャル広告を読み込めません: ${error.message}');
          completer.complete(null);
        },
      ),
    );

    return completer.future;
  }

  Future<RewardedAd?> _loadRewarded() {
    final completer = Completer<RewardedAd?>();

    RewardedAd.load(
      adUnitId: AdUnitIds.rewarded,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          AppLog.add('広告', 'リワード広告を読み込みました');
          completer.complete(ad);
        },
        onAdFailedToLoad: (error) {
          AppLog.add('広告', 'リワード広告を読み込めません: ${error.message}');
          completer.complete(null);
        },
      ),
    );

    return completer.future;
  }

  @override
  Future<void> showInterstitial() async {
    // 読み込みが始まっていなければ、次の表示に備えて始める
    final pending = _interstitial ??= _loadInterstitial();

    final ad = await pending.timeout(_waitLoad, onTimeout: () => null);

    // 使う広告は、次の表示のために読み込み直す
    _interstitial = _loadInterstitial();

    if (ad == null) {
      AppLog.add('広告', 'インタースティシャル広告を用意できていないため、表示しません');
      return;
    }

    final closed = Completer<void>();

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        closed.complete();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        AppLog.add('広告', 'インタースティシャル広告を表示できません: ${error.message}');
        ad.dispose();
        closed.complete();
      },
    );

    await ad.show();
    await closed.future;
  }

  @override
  Future<RewardedResult> showRewarded() async {
    final pending = _rewarded ??= _loadRewarded();

    final ad = await pending.timeout(_waitLoad, onTimeout: () => null);

    _rewarded = _loadRewarded();

    if (ad == null) {
      AppLog.add('広告', 'リワード広告を用意できていないため、表示しません');
      return RewardedResult.unavailable;
    }

    final closed = Completer<void>();
    var earned = false;
    var failed = false;

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        closed.complete();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        AppLog.add('広告', 'リワード広告を表示できません: ${error.message}');
        failed = true;
        ad.dispose();
        closed.complete();
      },
    );

    await ad.show(onUserEarnedReward: (_, __) => earned = true);
    await closed.future;

    if (failed) return RewardedResult.unavailable;
    return earned ? RewardedResult.earned : RewardedResult.dismissed;
  }
}
