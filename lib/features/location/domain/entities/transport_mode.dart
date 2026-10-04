/// 移動手段
enum TransportMode {
  walk('徒歩'),
  bicycle('自転車'),

  /// 車・電車などの区別がつかない場合(速度からの自動推定で使う)
  vehicle('乗り物'),
  car('車'),
  bus('バス'),
  train('電車'),
  other('その他');

  const TransportMode(this.label);

  final String label;
}
