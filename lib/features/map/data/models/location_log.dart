import 'package:isar/isar.dart';

part 'location_log.g.dart';

@collection
class LocationLog {
  Id id = Isar.autoIncrement;

  late double latitude;
  late double longitude;

  late DateTime timestamp;
}