import 'package:flutter/material.dart';
import 'package:auto_diary_ai/common/constants/app_colors.dart';
import 'package:auto_diary_ai/common/constants/app_sizes.dart';
import 'month_picker_sheet.dart';

/// 月の切り替え(ホーム画面と、カレンダー画面で、共通で使う)
///
/// 左右の丸いボタンで、日記のある月を、1つずつ移動する。
/// 「2026年 10月 ⌄」を押すと、年月を選ぶシートが出る。その下に、その月の記録の日数を出す。
/// 月は「2026-10」の形で扱う。[months]は、新しい月が先頭
class MonthBar extends StatelessWidget {
  const MonthBar({
    super.key,
    required this.months,
    required this.selectedMonth,
    this.recordedDays,
    required this.onChanged,
    this.compact = false,
  });

  final List<String> months;
  final String selectedMonth;

  /// 表示中の月に、日記を書いた日の数(nullなら、「記録 ◯日」は出さない)
  final int? recordedDays;

  final ValueChanged<String> onChanged;

  /// カレンダー画面用の、少し小さい形(年と月の文字、丸いボタン、余白)
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final index = months.indexOf(selectedMonth);
    final parts = selectedMonth.split('-');
    final year = int.parse(parts[0]);
    final month = int.parse(parts[1]);

    // 左が、ひとつ前(古い)の月、右が、ひとつ先(新しい)の月
    final older = index >= 0 && index < months.length - 1
        ? months[index + 1]
        : null;
    final newer = index > 0 ? months[index - 1] : null;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSizes.space16,
        AppSizes.space16,
        AppSizes.space16,
        compact ? AppSizes.space12 : AppSizes.space8,
      ),
      child: Column(
        children: [
          Row(
            children: [
              _RoundButton(
                key: const Key('homePreviousMonth'),
                size: compact ? 40 : 48,
                icon: Icons.chevron_left,
                tooltip: '前の月',
                onPressed: older == null ? null : () => onChanged(older),
              ),
              Expanded(
                child: InkWell(
                  key: const Key('homeMonthLabel'),
                  borderRadius: BorderRadius.circular(AppSizes.radius12),
                  onTap: () async {
                    final picked = await showMonthPickerSheet(
                      context,
                      months: months,
                      selectedMonth: selectedMonth,
                    );
                    if (picked != null && picked != selectedMonth) {
                      onChanged(picked);
                    }
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSizes.space4,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          '$year年',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            color: compact ? AppColors.textSub : AppColors.navy,
                          ),
                        ),
                        const SizedBox(width: AppSizes.space4),
                        Text(
                          '$month月',
                          style: TextStyle(
                            fontSize: compact ? 24 : 26,
                            // ホームは、普通の太さ。カレンダーは、太字
                            fontWeight: compact
                                ? FontWeight.w800
                                : FontWeight.w400,
                            color: compact
                                ? AppColors.text
                                : AppColors.navyDark,
                          ),
                        ),
                        const SizedBox(width: AppSizes.space4),
                        const Icon(
                          Icons.keyboard_arrow_down,
                          size: 22,
                          color: AppColors.navy,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              _RoundButton(
                key: const Key('homeNextMonth'),
                size: compact ? 40 : 48,
                icon: Icons.chevron_right,
                tooltip: '次の月',
                onPressed: newer == null ? null : () => onChanged(newer),
              ),
            ],
          ),
          if (recordedDays != null) ...[
            const SizedBox(height: AppSizes.space8),
            Container(
              key: const Key('homeRecordedDays'),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(AppSizes.radiusPill),
                border: Border.all(color: AppColors.line),
              ),
              child: Text.rich(
                TextSpan(
                  style: TextStyle(
                    fontSize: compact ? 12 : 13,
                    color: AppColors.textSub,
                  ),
                  children: [
                    const TextSpan(text: '記録 '),
                    TextSpan(
                      text: '$recordedDays日',
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        color: AppColors.navyDark,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _RoundButton extends StatelessWidget {
  const _RoundButton({
    super.key,
    required this.size,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final double size;
  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    return Material(
      color: AppColors.white,
      shape: const CircleBorder(side: BorderSide(color: AppColors.line)),
      child: IconButton(
        tooltip: tooltip,
        onPressed: onPressed,
        style: IconButton.styleFrom(
          fixedSize: Size(size, size),
          minimumSize: Size(size, size),
          padding: EdgeInsets.zero,
        ),
        icon: Icon(icon, color: enabled ? AppColors.navy : AppColors.chevron),
      ),
    );
  }
}
