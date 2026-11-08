import 'package:isar/isar.dart';
import '../../domain/entities/timeline_edit.dart';
import '../../domain/entities/transport_mode.dart';
import '../../domain/repositories/timeline_edit_repository.dart';
import '../models/timeline_edit_log.dart';

class TimelineEditRepositoryImpl implements TimelineEditRepository {
  final Isar isar;

  TimelineEditRepositoryImpl(this.isar);

  @override
  Future<List<TimelineEdit>> findOverlapping(
    DateTime start,
    DateTime end,
  ) async {
    final logs = await isar.timelineEditLogs
        .filter()
        .startLessThan(end)
        .endGreaterThan(start)
        .findAll();

    return logs.map(_toEntity).toList();
  }

  @override
  Future<void> save(TimelineEdit edit) async {
    final log = TimelineEditLog()
      ..type = edit.type.name
      ..start = edit.start
      ..end = edit.end
      ..placeName = edit.placeName
      ..transport = edit.transport?.name
      ..transportText = edit.transportText;

    final id = edit.id;
    if (id != null) {
      log.id = id;
    }

    await isar.writeTxn(() async {
      await isar.timelineEditLogs.put(log);
    });
  }

  @override
  Future<void> delete(int id) async {
    await isar.writeTxn(() async {
      await isar.timelineEditLogs.delete(id);
    });
  }

  TimelineEdit _toEntity(TimelineEditLog log) {
    return TimelineEdit(
      id: log.id,
      type: TimelineEditType.values.byName(log.type),
      start: log.start,
      end: log.end,
      placeName: log.placeName,
      transport: TransportMode.values
          .where((e) => e.name == log.transport)
          .firstOrNull,
      transportText: log.transportText,
    );
  }
}
