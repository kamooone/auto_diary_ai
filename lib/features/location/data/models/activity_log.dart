import 'package:isar/isar.dart';

part 'activity_log.g.dart';

/// OSが認識した行動の変化
/// ある行動は、次の記録の時刻まで続いていたものとして扱う
@collection
class ActivityLog {
  Id id = Isar.autoIncrement;

  /// その行動が始まった時刻
  @Index()
  late DateTime timestamp;

  /// 行動の種類(ActivityTypeの名前)
  late String type;
}
