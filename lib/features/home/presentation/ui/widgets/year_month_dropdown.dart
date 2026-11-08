import 'package:flutter/material.dart';

/// ホーム画面の、年と月のドロップダウン(日記の選択画面などと同じ形)
///
/// 月は「2026-10」の形で扱う。年を選ぶと、その年の中で一番新しい月を表示する
class YearMonthDropdown extends StatelessWidget {
  const YearMonthDropdown({
    super.key,
    required this.months,
    required this.selectedMonth,
    required this.onChanged,
  });

  /// 日記のある月(「2026-10」の形)
  final List<String> months;

  /// 表示中の月(「2026-10」の形。[months]に含まれるもの)
  final String selectedMonth;

  final ValueChanged<String> onChanged;

  static int _year(String month) => int.parse(month.split('-')[0]);

  static int _month(String month) => int.parse(month.split('-')[1]);

  @override
  Widget build(BuildContext context) {
    final selectedYear = _year(selectedMonth);

    // 新しい年・月を先頭にする
    final years = months.map(_year).toSet().toList()
      ..sort((a, b) => b.compareTo(a));
    final monthsOfYear = months
        .where((e) => _year(e) == selectedYear)
        .map(_month)
        .toSet()
        .toList()
      ..sort((a, b) => b.compareTo(a));

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Row(
        children: [
          Expanded(
            child: DropdownButtonFormField<int>(
              key: const Key('homeYear'),
              initialValue: selectedYear,
              decoration: const InputDecoration(
                labelText: "年",
                isDense: true,
                border: OutlineInputBorder(),
              ),
              items: [
                for (final year in years)
                  DropdownMenuItem(value: year, child: Text("$year年")),
              ],
              onChanged: (year) {
                if (year == null || year == selectedYear) return;

                // その年で一番新しい月(monthsは新しい月が先頭)
                onChanged(months.firstWhere((e) => _year(e) == year));
              },
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: DropdownButtonFormField<int>(
              key: Key('homeMonth-$selectedYear'),
              initialValue: _month(selectedMonth),
              decoration: const InputDecoration(
                labelText: "月",
                isDense: true,
                border: OutlineInputBorder(),
              ),
              items: [
                for (final month in monthsOfYear)
                  DropdownMenuItem(value: month, child: Text("$month月")),
              ],
              onChanged: (month) {
                if (month == null) return;

                onChanged(
                  "$selectedYear-${month.toString().padLeft(2, '0')}",
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
