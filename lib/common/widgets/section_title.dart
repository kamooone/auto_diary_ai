import 'package:flutter/material.dart';
import 'package:auto_diary_ai/common/constants/app_colors.dart';
import 'package:auto_diary_ai/common/constants/app_sizes.dart';

/// 見出し(まとまりの上に出す、小さな見出し)
///
/// 右側に、補足の文字を出せる。見出しと中身の間は、8
class SectionTitle extends StatelessWidget {
  const SectionTitle(this.title, {super.key, this.trailing});

  final String title;

  /// 右に出す、補足の文字
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSizes.space4,
        0,
        AppSizes.space4,
        AppSizes.space8,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.52,
                color: AppColors.textSub,
              ),
            ),
          ),
          if (trailing != null)
            Flexible(
              child: Text(
                trailing!,
                textAlign: TextAlign.right,
                style: const TextStyle(fontSize: 12, color: AppColors.textSub),
              ),
            ),
        ],
      ),
    );
  }
}
