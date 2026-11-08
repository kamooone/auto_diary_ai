import '../entities/plan_type.dart';

/// 現在のプランを保存・取得する
///
/// 課金を導入するときは、購読の状態から判定する実装に差し替える
abstract class PlanRepository {
  /// 現在のプラン(保存されていない場合は無料プラン)
  Future<PlanType> load();

  Future<void> save(PlanType plan);
}
