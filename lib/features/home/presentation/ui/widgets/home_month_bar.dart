import 'package:flutter/material.dart';
import 'package:auto_diary_ai/common/constants/app_colors.dart';
import 'package:auto_diary_ai/common/constants/app_sizes.dart';
import 'month_picker_sheet.dart';

/// ホーム画面の、月の切り替え
///
/// 左右の丸いボタンで、日記のある月を、1つずつ移動する。
/// 「2026年 10月 ⌄」を押すと、年月を選ぶシートが出る。その下に、その月の記録の日数を出す。
/// 月は「2026-10」の形で扱う。[months]は、新しい月が先頭
class HomeMonthBar extends StatelessWidget {
  const HomeMonthBar({
    super.key,
    required this.months,
    required this.selectedMonth,
    required this.recordedDays,
    required this.onChanged,
  });

  final List<String> months;
  final String selectedMonth;

  /// 表示中の月に、日記を書いた日の数
  final int recordedDays;

  final ValueChanged<String> onChanged;

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
      padding: const EdgeInsets.fromLTRB(
        AppSizes.space16,
        AppSizes.space16,
        AppSizes.space16,
        AppSizes.space8,
      ),
      child: Column(
        children: [
          Row(
            children: [
              _RoundButton(
                key: const Key('homePreviousMonth'),
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
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: AppColors.navy,
                          ),
                        ),
                        const SizedBox(width: AppSizes.space4),
                        Text(
                          '$month月',
                          style: const TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.w800,
                            color: AppColors.navyDark,
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
                icon: Icons.chevron_right,
                tooltip: '次の月',
                onPressed: newer == null ? null : () => onChanged(newer),
              ),
            ],
          ),
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
                style: const TextStyle(fontSize: 13, color: AppColors.textSub),
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
      ),
    );
  }
}

class _RoundButton extends StatelessWidget {
  const _RoundButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

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
        icon: Icon(icon, color: enabled ? AppColors.navy : AppColors.chevron),
      ),
    );
  }
}
