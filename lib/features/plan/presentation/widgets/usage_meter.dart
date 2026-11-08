import 'package:flutter/material.dart';
import '../../domain/entities/usage_info.dart';

/// 今月のAIの使用量を示す
class UsageMeter extends StatelessWidget {
  /// サーバーから取得できていない場合はnull
  final UsageInfo? usage;

  const UsageMeter({super.key, required this.usage});

  @override
  Widget build(BuildContext context) {
    final usage = this.usage;
    final theme = Theme.of(context);

    if (usage == null) {
      return Text(
        "今月の使用量を取得できていません",
        style: theme.textTheme.bodySmall,
      );
    }

    final percent = (usage.ratio * 100).floor();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(child: Text("今月のAIの使用量")),
            Text(
              "$percent%",
              style: theme.textTheme.titleSmall?.copyWith(
                color: usage.isExceeded ? theme.colorScheme.error : null,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        LinearProgressIndicator(
          value: usage.ratio,
          minHeight: 8,
          borderRadius: BorderRadius.circular(4),
          color: usage.isExceeded ? theme.colorScheme.error : null,
        ),
        const SizedBox(height: 4),
        Text(
          [
            "${_number(usage.usedTokens)} / ${_number(usage.limitTokens)} トークン",
            if (usage.resetsAt != null) "${_date(usage.resetsAt!)}にリセット",
          ].join("・"),
          style: theme.textTheme.bodySmall,
        ),
        if (usage.tokenBalance > 0)
          Text(
            "うち、アカウントのトークン ${_number(usage.tokenBalance)}",
            style: theme.textTheme.bodySmall,
          ),
      ],
    );
  }

  // 3桁ごとにカンマで区切る
  static String _number(int value) {
    return value.toString().replaceAllMapped(
          RegExp(r'\B(?=(\d{3})+(?!\d))'),
          (_) => ',',
        );
  }

  static String _date(DateTime date) {
    final local = date.toLocal();
    return "${local.month}月${local.day}日";
  }
}
