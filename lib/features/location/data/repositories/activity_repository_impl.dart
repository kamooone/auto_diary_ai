import 'package:isar/isar.dart';
import '../../domain/entities/activity_segment.dart';
import '../../domain/repositories/activity_repository.dart';
import '../models/activity_log.dart';
import '../services/activity_recording_service.dart';

class ActivityRepositoryImpl implements ActivityRepository {
  final Isar isar;

  ActivityRepositoryImpl(this.isar);

  // 開始時刻より前の記録がこれより古い場合、その行動が続いていたとはみなさない
  static const _maxCarryOver = Duration(hours: 12);

  @override
  Future<List<ActivitySegment>> getActivities(
    DateTime start,
    DateTime end,
  ) async {
    // ネイティブ側の記録を先に取り込む
    await importRecordedActivities(isar);

    // 開始時刻の時点で続いていた行動
    final previous = await isar.activityLogs
        .filter()
        .timestampLessThan(start)
        .sortByTimestampDesc()
        .findFirst();

    final logs = await isar.activityLogs
        .filter()
        .timestampBetween(start, end)
        .sortByTimestamp()
        .findAll();

    final all = [
      if (previous != null &&
          start.difference(previous.timestamp) <= _maxCarryOver)
        previous,
      ...logs,
    ];

    final segments = <ActivitySegment>[];

    for (var i = 0; i < all.length; i++) {
      final type = ActivityType.values
          .where((e) => e.name == all[i].type)
          .firstOrNull;
      if (type == null) continue;

      // ある行動は、次の記録の時刻まで続いていたものとして扱う
      final segmentStart =
          all[i].timestamp.isBefore(start) ? start : all[i].timestamp;
      final segmentEnd = i + 1 < all.length ? all[i + 1].timestamp : end;

      if (segmentEnd.isAfter(segmentStart)) {
        segments.add(
          ActivitySegment(start: segmentStart, end: segmentEnd, type: type),
        );
      }
    }

    return segments;
  }
}
