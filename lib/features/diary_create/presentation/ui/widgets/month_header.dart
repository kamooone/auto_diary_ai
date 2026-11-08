import 'package:flutter/material.dart';

/// 選択画面の、月ごとの見出し
/// 「この月をすべて選択」で、その月の項目をまとめて選択・解除できる。
/// 見出しを押すと、その月の項目を開閉できる(アコーディオン)
class MonthHeader extends StatelessWidget {
  const MonthHeader({
    super.key,
    required this.month,
    required this.selectedCount,
    required this.totalCount,
    required this.onToggle,
    this.isExpanded = true,
    this.onTap,
  });

  /// 月(1日の0時)
  final DateTime month;

  /// その月の項目のうち、選択している数と、全体の数
  final int selectedCount;
  final int totalCount;

  final VoidCallback onToggle;

  /// その月の項目が開いているか
  final bool isExpanded;

  /// 見出しを押したときの動き(開閉)
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isAllSelected = totalCount > 0 && selectedCount == totalCount;
    final scheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      color: scheme.primaryContainer,
      padding: const EdgeInsets.only(left: 4, right: 4),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: onTap,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Row(
                  children: [
                    Icon(
                      isExpanded ? Icons.expand_more : Icons.chevron_right,
                      color: scheme.onPrimaryContainer,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        "${month.year}年${month.month}月  $selectedCount/$totalCount",
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(color: scheme.onPrimaryContainer),
                      ),
                    ),
                  ],
                ),
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
