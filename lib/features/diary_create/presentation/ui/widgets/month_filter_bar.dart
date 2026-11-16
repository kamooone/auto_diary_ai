import 'package:flutter/material.dart';
import '../../../../../common/constants/app_sizes.dart';
import '../../../../../common/widgets/filter_chip_field.dart';
import '../../../domain/services/month_filter.dart';

/// 年と月のセレクトボックス。一覧を絞り込むのに使う
/// 項目がないときは、何も表示しない
class MonthFilterBar extends StatelessWidget {
  const MonthFilterBar({
    super.key,
    required this.times,
    required this.value,
    required this.onChanged,
    this.chipStyle = false,
  });

  /// 一覧にある項目の日時(選択肢を決めるのに使う)
  final List<DateTime> times;
  final MonthFilter value;
  final ValueChanged<MonthFilter> onChanged;

  /// true のとき、丸い札の見た目にする(押すと、選択肢のメニューが開く)
  final bool chipStyle;

  @override
  Widget build(BuildContext context) {
    if (times.isEmpty) return const SizedBox.shrink();

    final years = MonthFilter.yearsOf(times);
    final months = value.year == null
        ? <int>[]
        : MonthFilter.monthsOf(times, value.year!);

    if (chipStyle) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSizes.space16,
          AppSizes.space4,
          AppSizes.space16,
          AppSizes.space8,
        ),
        child: Row(
          children: [
            FilterChipField<int>(
              key: const Key('filterYear'),
              label: "年",
              value: value.year,
              options: [
                (null, "すべて"),
                for (final year in years) (year, "$year年"),
              ],
              onChanged: (year) => onChanged(value.withYear(year)),
            ),
            const SizedBox(width: AppSizes.space8),
            FilterChipField<int>(
              key: Key('filterMonth-${value.year}'),
              label: "月",
              value: value.month,
              options: [
                (null, "すべて"),
                for (final month in months) (month, "$month月"),
              ],
              // 年を選ぶまでは、月は選べない
              onChanged: value.year == null
                  ? null
                  : (month) => onChanged(value.withMonth(month)),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Row(
        children: [
          Expanded(
            child: DropdownButtonFormField<int?>(
              key: const Key('filterYear'),
              initialValue: value.year,
              decoration: const InputDecoration(
                labelText: "年",
                isDense: true,
                border: OutlineInputBorder(),
              ),
              items: [
                const DropdownMenuItem(value: null, child: Text("すべて")),
                for (final year in years)
                  DropdownMenuItem(value: year, child: Text("$year年")),
              ],
              onChanged: (year) => onChanged(value.withYear(year)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: DropdownButtonFormField<int?>(
              key: Key('filterMonth-${value.year}'),
              initialValue: value.month,
              decoration: const InputDecoration(
                labelText: "月",
                isDense: true,
                border: OutlineInputBorder(),
              ),
              items: [
                const DropdownMenuItem(value: null, child: Text("すべて")),
                for (final month in months)
                  DropdownMenuItem(value: month, child: Text("$month月")),
              ],
              // 年を選ぶまでは、月は選べない
              onChanged: value.year == null
                  ? null
                  : (month) => onChanged(value.withMonth(month)),
            ),
          ),
        ],
      ),
    );
  }
}
