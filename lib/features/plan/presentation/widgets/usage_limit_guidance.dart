import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/router/app_routes.dart';
import '../../domain/entities/plan_availability.dart';

/// 今月の枠を使い切ったときの案内
///
/// - 有料プランがない間(今): 来月に枠が戻ること・ポイントをトークンに交換できること
/// - 有料プランを出すとき: 有料プランの案内と、プランの画面へのボタン
class UsageLimitGuidance extends StatelessWidget {
  const UsageLimitGuidance({
    super.key,
    this.isPaid = false,
    this.paidPlanAvailable = paidPlanEnabled,
  });

  /// 有料プランで使っているか(有料プランを出すときだけ使う)
  final bool isPaid;

  /// 有料プランを画面に出すか(初めは[paidPlanEnabled])
  final bool paidPlanAvailable;

  @override
  Widget build(BuildContext context) {
    final error = TextStyle(color: Theme.of(context).colorScheme.error);

    if (paidPlanAvailable) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isPaid
                ? "今月の使用量の上限に達しました。次のリセットまでAIは使えません。"
                : "今月の使用量の上限に達しました。有料プランにすると、さらに多く使えます。",
            style: error,
          ),
          if (!isPaid)
            TextButton(
              onPressed: () => context.push(AppRoutes.plan),
              child: const Text("プランを見る"),
            ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("今月の枠を使い切りました。来月の初めに、枠が戻ります。", style: error),
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
