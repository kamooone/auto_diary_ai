import 'package:flutter/material.dart';

/// 選択画面の、月ごとの見出し
/// 「この月をすべて選択」で、その月の項目をまとめて選択・解除できる
class MonthHeader extends StatelessWidget {
  const MonthHeader({
    super.key,
    required this.month,
    required this.selectedCount,
    required this.totalCount,
    required this.onToggle,
  });

  /// 月(1日の0時)
  final DateTime month;

  /// その月の項目のうち、選択している数と、全体の数
  final int selectedCount;
  final int totalCount;

  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final isAllSelected = totalCount > 0 && selectedCount == totalCount;
    final scheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      color: scheme.primaryContainer,
      padding: const EdgeInsets.only(left: 16, right: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              "${month.year}年${month.month}月  $selectedCount/$totalCount",
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: scheme.onPrimaryContainer,
              ),
            ),
          ),
          TextButton(
            onPressed: onToggle,
            child: Text(isAllSelected ? "この月を解除" : "この月をすべて選択"),
          ),
        ],
      ),
    );
  }
}
