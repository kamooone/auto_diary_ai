class LocationConstants {

  // この距離(m)を移動するごとに位置情報を受け取る
  static const int distanceFilterMeters = 10;

  // 誤差がこの距離(m)より大きい位置は記録しない
  static const double maxAccuracyMeters = 100;
}
