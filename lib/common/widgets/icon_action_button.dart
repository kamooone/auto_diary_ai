import 'package:flutter/material.dart';
import 'package:auto_diary_ai/common/constants/app_colors.dart';

/// カードの中の、小さなアイコンのボタン(40×40、背景なし)
///
/// [label]は、長押しで出る説明と、読み上げの名前になる
class IconActionButton extends StatelessWidget {
  const IconActionButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: label,
      onPressed: onPressed,
      style: IconButton.styleFrom(
        fixedSize: const Size(40, 40),
        minimumSize: const Size(40, 40),
        padding: EdgeInsets.zero,
      ),
      icon: Icon(icon, size: 18, color: AppColors.textSub),
    );
  }
}
