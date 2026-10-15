import '../../../plan/domain/entities/plan_type.dart';

/// 日記作成の制限(プランごとに変わる)
class DiaryPlan {
  final PlanType type;

  /// AIに書いてもらう日記で、複数日の期間を選べるか
  /// (選べない場合は、選んだ1日分の情報だけをAIに渡せる)
  final bool allowsMultipleDays;

  /// 1回の日記でAIに渡せる写真の枚数
  final int maxPhotos;

  const DiaryPlan({
    required this.type,
    required this.allowsMultipleDays,
    required this.maxPhotos,
  });

  /// 無料プラン: 選んだ1日分の情報だけをAIに渡せる
  static const free = DiaryPlan(
    type: PlanType.free,
    allowsMultipleDays: false,
    maxPhotos: 10,
  );

  /// 有料プラン: 選んだ期間の情報をAIに渡せる
  // 写真の枚数は仮の値(AWS側の1回の送信サイズの制限は10枚)
  static const paid = DiaryPlan(
    type: PlanType.paid,
    allowsMultipleDays: true,
    maxPhotos: 10,
  );

  static DiaryPlan forType(PlanType type) {
    return switch (type) {
      PlanType.free => free,
      PlanType.paid => paid,
    };
  }
}
