import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/router/app_routes.dart';

/// 今月の枠を使い切ったときの案内(来月に枠が戻ること・トークンに交換できること)
class UsageLimitGuidance extends StatelessWidget {
  const UsageLimitGuidance({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "今月の枠を使い切りました。来月の初めに、枠が戻ります。",
          style: TextStyle(color: Theme.of(context).colorScheme.error),
        ),
        const SizedBox(height: 4),
        Text(
          "ゲームでポイントを貯めて、Webでトークンに交換すると、"
          "続けて使えます。",
          style: Theme.of(context).textTheme.bodySmall,
        ),
        TextButton(
          onPressed: () => context.push(AppRoutes.points),
          child: const Text("ポイント・トークンを見る"),
        ),
      ],
    );
  }
}
