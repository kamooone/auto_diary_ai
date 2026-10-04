/// 滞在場所の周辺にある施設の候補
class PlaceCandidate {
  final String name;

  /// 施設の種類(カフェ、コンビニなど。分からない場合はnull)
  final String? category;

  /// 滞在場所からの距離(m)
  final double distanceMeters;

  const PlaceCandidate({
    required this.name,
    this.category,
    required this.distanceMeters,
  });
}
