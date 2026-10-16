import 'package:flutter/material.dart';

/// 選択画面の、日付ごとの見出し
/// 「この日をすべて選択」で、その日の項目をまとめて選択・解除できる
class DayHeader extends StatelessWidget {
  const DayHeader({
    super.key,
    required this.date,
    required this.selectedCount,
    required this.totalCount,
    required this.onToggle,
  });

  final DateTime date;

  /// その日の項目のうち、選択している数と、全体の数
  final int selectedCount;
  final int totalCount;

  final VoidCallback onToggle;

  static const _weekdays = ['月', '火', '水', '木', '金', '土', '日'];

  /// 「2026年1月1日（木）」の形
  static String dateText(DateTime date) {
    return "${date.year}年${date.month}月${date.day}日"
        "（${_weekdays[date.weekday - 1]}）";
  }

  @override
  Widget build(BuildContext context) {
    final isAllSelected = totalCount > 0 && selectedCount == totalCount;

    return Container(
      width: double.infinity,
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      padding: const EdgeInsets.only(left: 16, right: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              "${dateText(date)}  $selectedCount/$totalCount",
              style: Theme.of(context).textTheme.titleSmall,
            ),
          ),
          TextButton(
            onPressed: onToggle,
            child: Text(isAllSelected ? "この日を解除" : "この日をすべて選択"),
          ),
        ],
      ),
    );
  }
}
