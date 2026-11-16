import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../../../core/logging/app_log.dart';
import '../../../common/constants/app_colors.dart';
import '../application/ads_provider.dart';
import '../data/ad_unit_ids.dart';

/// バナー広告(読み込めるまで、広告を表示しない)
class BannerAdView extends ConsumerStatefulWidget {
  const BannerAdView({super.key, this.band = false});

  /// trueのとき、広告を、白い帯(上に細い線)の中に置く(ホーム画面用)
  final bool band;

  @override
  ConsumerState<BannerAdView> createState() => _BannerAdViewState();
}

class _BannerAdViewState extends ConsumerState<BannerAdView> {
  BannerAd? _ad;
  bool _isLoaded = false;

  @override
  void initState() {
    super.initState();

    if (!ref.read(adsEnabledProvider)) return;

    _ad = BannerAd(
      adUnitId: AdUnitIds.banner,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) {
          if (mounted) setState(() => _isLoaded = true);
        },
        onAdFailedToLoad: (ad, error) {
          AppLog.add('広告', 'バナー広告を読み込めません: ${error.message}');
          ad.dispose();
          if (mounted) setState(() => _ad = null);
        },
      ),
    )..load();
  }

  @override
  void dispose() {
    _ad?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ad = _ad;
    if (ad == null || !_isLoaded) return const SizedBox.shrink();

    final adView = SizedBox(
      width: ad.size.width.toDouble(),
      height: ad.size.height.toDouble(),
      child: AdWidget(ad: ad),
    );
    if (!widget.band) return adView;

    return Container(
      width: double.infinity,
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(vertical: 4),
      decoration: const BoxDecoration(
        color: AppColors.white,
        border: Border(top: BorderSide(color: AppColors.line)),
      ),
      child: adView,
    );
  }
}
