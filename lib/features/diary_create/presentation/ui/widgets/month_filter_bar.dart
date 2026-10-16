import 'package:flutter/material.dart';
import '../../../domain/services/month_filter.dart';

/// 年と月のセレクトボックス。一覧を絞り込むのに使う
/// 複数の月にまたがっていないときは、何も表示しない
class MonthFilterBar extends StatelessWidget {
  const MonthFilterBar({
    super.key,
    required this.times,
    required this.value,
    required this.onChanged,
  });

  /// 一覧にある項目の日時(選択肢を決めるのに使う)
  final List<DateTime> times;
  final MonthFilter value;
  final ValueChanged<MonthFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    if (!MonthFilter.needed(times)) return const SizedBox.shrink();

    final years = MonthFilter.yearsOf(times);
    final months =
        value.year == null ? <int>[] : MonthFilter.monthsOf(times, value.year!);

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
