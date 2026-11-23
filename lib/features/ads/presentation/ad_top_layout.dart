import 'package:flutter/material.dart';
import 'banner_ad_view.dart';

/// 画面の上(アプリバーのすぐ下)にバナー広告を置き、その下に[child]を広げる
///
/// 広告を読み込めるまでは、広告の場所は空く(何も表示しない)
class AdTopLayout extends StatelessWidget {
  const AdTopLayout({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const BannerAdView(band: true, atTop: true),
        Expanded(child: child),
      ],
    );
  }
}
