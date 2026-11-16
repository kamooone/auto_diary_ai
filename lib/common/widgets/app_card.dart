import 'package:flutter/material.dart';
import 'package:auto_diary_ai/common/constants/app_colors.dart';
import 'package:auto_diary_ai/common/constants/app_sizes.dart';

/// 白い面に、角丸16と、カード用の影を付けた、カード
///
/// 中身は、角からはみ出さないように切り取る。中の行を押したときの波紋も、カードの角で止まる
class AppCard extends StatelessWidget {
  const AppCard({super.key, required this.child, this.padding});

  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppSizes.radius16),
        boxShadow: AppColors.cardShadows,
      ),
      child: Material(
        type: MaterialType.transparency,
        child: padding == null ? child : Padding(padding: padding!, child: child),
      ),
    );
  }
}
