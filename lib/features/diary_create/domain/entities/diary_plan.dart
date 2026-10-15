import '../../../plan/domain/entities/plan_type.dart';

/// 日記作成の制限(プランごとに変わる)
class DiaryPlan {
  final PlanType type;

  /// 1回の日記で対象にできる日数
  final int maxDays;

  /// 1回の日記でAIに渡せる写真の枚数
  final int maxPhotos;

  const DiaryPlan({
    required this.type,
    required this.maxDays,
    required this.maxPhotos,
  });

  /// 無料プラン: 選んだ1日分の情報だけをAIに渡せる
  static const free = DiaryPlan(
    type: PlanType.free,
    maxDays: 1,
    maxPhotos: 10,
  );

  /// 有料プラン: 複数日分の情報をAIに渡せる
  // 日数と写真の枚数は仮の値(AWS側の1回の送信サイズの制限は10枚)
  static const paid = DiaryPlan(
    type: PlanType.paid,
    maxDays: 7,
    maxPhotos: 10,
  );

  static DiaryPlan forType(PlanType type) {
    return switch (type) {
      PlanType.free => free,
      PlanType.paid => paid,
    };
  }

  /// 複数日の日記を作れるか
  bool get allowsMultipleDays => maxDays > 1;
}
