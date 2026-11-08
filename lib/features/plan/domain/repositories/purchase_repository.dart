import '../entities/plan_product.dart';

/// 購入・復元の結果
enum PurchaseOutcome {
  /// 購入できた(サーバーでの確認はこのあと)
  purchased,

  /// 購入をやめた
  cancelled,

  /// 支払いの承認待ち
  pending,

  /// 購入に失敗した
  failed,

  /// この端末では購入できない(ストアに接続できない、未対応など)
  unavailable,
}

/// アプリ内課金(Google Play・App Store)
abstract class PurchaseRepository {
  /// 販売している有料プランを取得する(取得できない場合は空)
  Future<List<PlanProduct>> loadProducts();

  Future<PurchaseOutcome> buy(PlanProduct product);

  /// 以前の購入を復元する(機種変更や再インストールのとき)
  Future<PurchaseOutcome> restore();
}

/// アプリ内課金をまだ使えない状態(課金の実装を入れるまでの仮の実装)
class UnavailablePurchaseRepository implements PurchaseRepository {
  @override
  Future<List<PlanProduct>> loadProducts() async => const [];

  @override
  Future<PurchaseOutcome> buy(PlanProduct product) async =>
      PurchaseOutcome.unavailable;

  @override
  Future<PurchaseOutcome> restore() async => PurchaseOutcome.unavailable;
}
