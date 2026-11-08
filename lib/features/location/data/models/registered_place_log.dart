import 'package:isar/isar.dart';

part 'registered_place_log.g.dart';

/// ユーザーが場所名を入力して登録した場所
@collection
class RegisteredPlaceLog {
  Id id = Isar.autoIncrement;

  late double latitude;
  late double longitude;

  late String name;
}
