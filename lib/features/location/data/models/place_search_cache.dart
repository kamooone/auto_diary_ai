import 'package:isar/isar.dart';

part 'place_search_cache.g.dart';

/// 施設の検索結果
/// 同じ場所を何度も問い合わせないよう、座標ごとに保存する
@collection
class PlaceSearchCache {
  Id id = Isar.autoIncrement;

  /// 丸めた座標(緯度,経度)
  @Index()
  late String key;

  /// 候補の一覧(JSON)
  late String candidatesJson;

  late DateTime fetchedAt;
}
