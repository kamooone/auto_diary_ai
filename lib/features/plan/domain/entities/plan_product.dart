/// ストア(Google Play・App Store)で販売している有料プラン
class PlanProduct {
  /// ストアの商品ID
  final String id;

  final String title;

  /// ストアが返す、通貨記号つきの価格(例: ¥480)
  final String price;

  /// 課金の周期の説明(例: 1か月)
  final String? period;

  const PlanProduct({
    required this.id,
    required this.title,
    required this.price,
    this.period,
  });
}
