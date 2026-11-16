import 'package:flutter/material.dart';
import 'package:auto_diary_ai/common/constants/app_colors.dart';
import 'package:auto_diary_ai/common/constants/app_sizes.dart';

/// 選ぶ項目の行(日付・期間・写真・材料・日記などを選ぶ画面への入り口)
///
/// 左に、ピンクの丸とアイコン、中央に項目名と値、右に矢印。
/// [enabled]がfalseのとき(データがなく、押せない)は、グレーの見た目にする。
/// 1枚のカードに複数の行を入れるときは、行の間に、細い線を入れる(`Divider`は、呼ぶ側で足す)
class SelectRow extends StatelessWidget {
  const SelectRow({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
    this.enabled = true,
    this.trailing,
  });

  final IconData icon;

  /// 項目名(小さく、上に出す)
  final String label;

  /// 値(大きく、下に出す)
  final String value;

  final VoidCallback? onTap;

  /// falseのときは、押せず、グレーの見た目になる
  final bool enabled;

  /// 右の矢印の代わりに出すもの(読み込み中のくるくるなど)
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: enabled ? onTap : null,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 64),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSizes.space16,
            AppSizes.space12,
            AppSizes.space12,
            AppSizes.space12,
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: enabled ? AppColors.pink : AppColors.mutedCircle,
                ),
                child: Icon(
                  icon,
                  size: 20,
                  color: enabled ? AppColors.navy : AppColors.chevron,
                ),
              ),
              const SizedBox(width: AppSizes.space12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSub,
                      ),
                    ),
                    Text(
                      value,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: enabled ? AppColors.text : AppColors.mutedText,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSizes.space8),
              trailing ??
                  const Icon(
                    Icons.chevron_right,
                    size: 18,
                    color: AppColors.chevron,
                  ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 1枚のカードの中の、行と行の間の線(1px)
class RowDivider extends StatelessWidget {
  const RowDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return const Divider(height: 1, thickness: 1, color: AppColors.line);
  }
}
