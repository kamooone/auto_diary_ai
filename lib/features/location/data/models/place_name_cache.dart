import 'package:isar/isar.dart';

part 'place_name_cache.g.dart';

/// 座標から取得した地名
/// 同じ場所を何度も問い合わせないよう、座標ごとに保存する
@collection
class PlaceNameCache {
  Id id = Isar.autoIncrement;

  /// 丸めた座標(緯度,経度)
  @Index()
  late String key;

  late String name;

  late DateTime fetchedAt;
}
