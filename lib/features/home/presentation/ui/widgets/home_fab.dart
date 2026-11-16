import 'package:flutter/material.dart';
import 'package:auto_diary_ai/common/constants/app_colors.dart';

/// ホーム画面の右下の、書くボタン(「＋ 日記を書く」)
///
/// オレンジ(濃)の塗りに、白い文字。影は、ボタンと同じ色
class HomeFab extends StatelessWidget {
  const HomeFab({
    super.key,
    required this.label,
    required this.tooltip,
    required this.heroTag,
    required this.onPressed,
  });

  final String label;
  final String tooltip;
  final Object heroTag;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        shape: BoxShape.rectangle,
        borderRadius: BorderRadius.all(Radius.circular(999)),
        boxShadow: [
          BoxShadow(
            color: AppColors.fabShadow,
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: FloatingActionButton.extended(
        heroTag: heroTag,
        tooltip: tooltip,
        onPressed: onPressed,
        backgroundColor: AppColors.orangeDark,
        foregroundColor: AppColors.white,
        elevation: 0,
        focusElevation: 0,
        hoverElevation: 0,
        highlightElevation: 0,
        shape: const StadiumBorder(),
        icon: const Icon(Icons.add),
        label: Text(
          label,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}
