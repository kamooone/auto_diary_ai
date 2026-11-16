import 'package:flutter/material.dart';
import 'package:auto_diary_ai/common/constants/app_colors.dart';
import 'package:auto_diary_ai/common/constants/app_sizes.dart';

/// 設定画面の1行(左にピンクの丸とアイコン、中央に項目名と説明、右に矢印やスイッチ)
///
/// 1枚のカードに複数の行を入れるときは、行の間に`RowDivider`を入れる。
/// [muted]がtrueのとき(開発用など)は、グレーの見た目にする
class SettingsRow extends StatelessWidget {
  const SettingsRow({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.extra,
    this.trailing,
    this.onTap,
    this.muted = false,
  });

  final IconData icon;
  final String title;

  /// 項目名の下の説明
  final String? subtitle;

  /// 説明の下に出すもの(ボタンなど)
  final Widget? extra;

  /// 右に出すもの。渡さず、[onTap]があるときは、矢印を出す
  final Widget? trailing;

  final VoidCallback? onTap;

  final bool muted;

  @override
  Widget build(BuildContext context) {
    final right =
        trailing ??
        (onTap == null
            ? null
            : const Icon(
                Icons.chevron_right,
                size: 18,
                color: AppColors.chevron,
              ));

    return InkWell(
      onTap: onTap,
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
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: muted ? AppColors.mutedCircle : AppColors.pink,
                ),
                child: Icon(
                  icon,
                  size: 20,
                  color: muted ? AppColors.mutedText : AppColors.navy,
                ),
              ),
              const SizedBox(width: AppSizes.space12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.text,
                      ),
                    ),
                    if (subtitle != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          subtitle!,
                          style: const TextStyle(
                            fontSize: 13,
                            height: 1.5,
                            color: AppColors.textSub,
                          ),
                        ),
                      ),
                    if (extra != null)
                      Padding(
                        padding: const EdgeInsets.only(top: AppSizes.space8),
                        child: extra!,
                      ),
                  ],
                ),
              ),
              if (right != null) ...[
                const SizedBox(width: AppSizes.space8),
                right,
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// 行の中の、小さな丸いボタン(白い面にうすい枠、ネイビーの太字)
class SettingsPillButton extends StatelessWidget {
  const SettingsPillButton({
    super.key,
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.white,
      shape: const StadiumBorder(side: BorderSide(color: AppColors.line)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.space16,
            vertical: AppSizes.space8,
          ),
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.navy,
            ),
          ),
        ),
      ),
    );
  }
}
