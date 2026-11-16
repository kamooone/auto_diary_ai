import 'package:flutter/material.dart';
import 'package:auto_diary_ai/common/constants/app_colors.dart';
import 'package:auto_diary_ai/common/constants/app_sizes.dart';

/// 年月を選ぶシートを出す。選んだ月(「2026-10」の形)を返す。選ばずに閉じたら、null
///
/// 日記のある月だけ、選べる。[months]は、日記のある月(新しい月が先頭)
Future<String?> showMonthPickerSheet(
  BuildContext context, {
  required List<String> months,
  required String selectedMonth,
}) {
  return showModalBottomSheet<String>(
    context: context,
    backgroundColor: AppColors.pageBackground,
    barrierColor: AppColors.scrim,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) =>
        _MonthPickerSheet(months: months, selectedMonth: selectedMonth),
  );
}

class _MonthPickerSheet extends StatefulWidget {
  const _MonthPickerSheet({required this.months, required this.selectedMonth});

  final List<String> months;
  final String selectedMonth;

  @override
  State<_MonthPickerSheet> createState() => _MonthPickerSheetState();
}

class _MonthPickerSheetState extends State<_MonthPickerSheet> {
  late int _year = int.parse(widget.selectedMonth.split('-')[0]);

  // 日記のある年(新しい年が先頭)
  late final List<int> _years =
      widget.months.map((e) => int.parse(e.split('-')[0])).toSet().toList()
        ..sort((a, b) => b.compareTo(a));

  @override
  Widget build(BuildContext context) {
    final yearIndex = _years.indexOf(_year);
    final olderYear = yearIndex >= 0 && yearIndex < _years.length - 1
        ? _years[yearIndex + 1]
        : null;
    final newerYear = yearIndex > 0 ? _years[yearIndex - 1] : null;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSizes.space16,
          AppSizes.space12,
          AppSizes.space16,
          AppSizes.space24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // つまみ
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.sheetHandle,
                borderRadius: BorderRadius.circular(AppSizes.radiusPill),
              ),
            ),
            const SizedBox(height: AppSizes.space16),
            Row(
              children: [
                IconButton(
                  key: const Key('sheetPreviousYear'),
                  tooltip: '前の年',
                  onPressed: olderYear == null
                      ? null
                      : () => setState(() => _year = olderYear),
                  icon: const Icon(Icons.chevron_left),
                  color: AppColors.navy,
                ),
                Expanded(
                  child: Text(
                    '$_year年',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w400,
                      color: AppColors.navyDark,
                    ),
                  ),
                ),
                IconButton(
                  key: const Key('sheetNextYear'),
                  tooltip: '次の年',
                  onPressed: newerYear == null
                      ? null
                      : () => setState(() => _year = newerYear),
                  icon: const Icon(Icons.chevron_right),
                  color: AppColors.navy,
                ),
              ],
            ),
            const SizedBox(height: AppSizes.space12),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 4,
              mainAxisSpacing: AppSizes.space8,
              crossAxisSpacing: AppSizes.space8,
              childAspectRatio: 1.7,
              children: [
                for (var month = 1; month <= 12; month++) _monthButton(month),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _monthButton(int month) {
    final key = '$_year-${month.toString().padLeft(2, '0')}';
    final enabled = widget.months.contains(key);
    final selected = key == widget.selectedMonth;

    return Material(
      color: selected ? AppColors.navy : AppColors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.radius12),
        side: BorderSide(
          color: selected || !enabled ? Colors.transparent : AppColors.line,
        ),
      ),
      child: InkWell(
        key: Key('sheetMonth-$key'),
        borderRadius: BorderRadius.circular(AppSizes.radius12),
        onTap: enabled ? () => Navigator.of(context).pop(key) : null,
        child: Center(
          child: Text(
            '$month月',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: selected
                  ? AppColors.white
                  : enabled
                  ? AppColors.navyDark
                  : AppColors.chevron,
            ),
          ),
        ),
      ),
    );
  }
}
