import 'package:isar/isar.dart';
part 'shared_post_model.g.dart';

@collection
class SharedPostModel {
  Id id = Isar.autoIncrement;

  late String url;
  late String text;
  late DateTime receivedAt;

  /// 結びつけた端末の写真のID(古いデータでは空)
  List<String> photoIds = [];

  SharedPostModel();
}