import '../../../plan/domain/entities/plan_type.dart';

/// 日記作成の制限(プランごとに変わる)
class DiaryPlan {
  final PlanType type;

  /// AIに書いてもらう日記で、複数日の期間を選べるか
  /// (選べない場合は、選んだ1日分の情報だけをAIに渡せる)
  /// 有料プランを画面から隠している間は、無料プランも複数日を選べる
  final bool allowsMultipleDays;

  const DiaryPlan({
    required this.type,
    required this.allowsMultipleDays,
  });

  /// 無料プラン: 選んだ期間の情報をAIに渡せる
  static const free = DiaryPlan(
    type: PlanType.free,
    allowsMultipleDays: true,
  );

  /// 有料プラン: 選んだ期間の情報をAIに渡せる
  static const paid = DiaryPlan(
    type: PlanType.paid,
    allowsMultipleDays: true,
  );

  static DiaryPlan forType(PlanType type) {
    return switch (type) {
      PlanType.free => free,
      PlanType.paid => paid,
    };
  }
}
