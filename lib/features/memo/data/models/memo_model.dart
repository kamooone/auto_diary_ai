import 'package:isar/isar.dart';
part 'memo_model.g.dart';

@collection
class MemoModel {
  Id id = Isar.autoIncrement;

  late String text;

  @Index()
  late DateTime createdAt;

  late List<String> photoIds;

  MemoModel();
}
