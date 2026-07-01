import 'package:isar/isar.dart';
part 'shared_post_entity.g.dart';

@collection
class SharedPostEntity {
  Id id = Isar.autoIncrement;

  late String url;
  late String text;
  late DateTime receivedAt;

  SharedPostEntity();
}