import 'dart:convert';
import 'package:isar/isar.dart';
import '../../domain/entities/timeline_item.dart';
import '../../domain/entities/transport_mode.dart';
import '../../domain/repositories/timeline_snapshot_repository.dart';
import '../models/timeline_snapshot.dart';

class TimelineSnapshotRepositoryImpl implements TimelineSnapshotRepository {
  final Isar isar;

  TimelineSnapshotRepositoryImpl(this.isar);

  // 滞在・移動の判定や、保存する項目を変えた場合は、この値を上げる
  static const _version = 1;

  @override
  Future<List<TimelineItem>?> find(
    DateTime date, {
    required int locationCount,
  }) async {
    final snapshot = await isar.timelineSnapshots
        .filter()
        .dateEqualTo(_day(date))
        .findFirst();

    if (snapshot == null) return null;
    if (snapshot.version != _version) return null;
    if (snapshot.locationCount != locationCount) return null;

    final items = jsonDecode(snapshot.itemsJson) as List;

    return [
      for (final item in items) _fromJson(item as Map<String, dynamic>),
    ];
  }

  @override
  Future<void> save(
    DateTime date,
    List<TimelineItem> items, {
    required int locationCount,
  }) async {
    final day = _day(date);

    final snapshot = TimelineSnapshot()
      ..date = day
      ..version = _version
      ..locationCount = locationCount
      ..itemsJson = jsonEncode([for (final item in items) _toJson(item)])
      ..savedAt = DateTime.now();

    await isar.writeTxn(() async {
      // 同じ日の結果がすでにある場合は上書きする
      final existing =
          await isar.timelineSnapshots.filter().dateEqualTo(day).findFirst();
      if (existing != null) {
        snapshot.id = existing.id;
      }

      await isar.timelineSnapshots.put(snapshot);
    });
  }

  DateTime _day(DateTime date) => DateTime(date.year, date.month, date.day);

  Map<String, dynamic> _toJson(TimelineItem item) {
    return switch (item) {
      Stay() => {
          'type': 'stay',
          'start': item.start.millisecondsSinceEpoch,
          'end': item.end.millisecondsSinceEpoch,
          'latitude': item.latitude,
          'longitude': item.longitude,
          'placeName': item.placeName,
          'estimatedPlaceName': item.estimatedPlaceName,
        },
      Move() => {
          'type': 'move',
          'start': item.start.millisecondsSinceEpoch,
          'end': item.end.millisecondsSinceEpoch,
          'distanceMeters': item.distanceMeters,
          'transport': item.transport?.name,
        },
    };
  }

  TimelineItem _fromJson(Map<String, dynamic> json) {
    final start = DateTime.fromMillisecondsSinceEpoch(json['start'] as int);
    final end = DateTime.fromMillisecondsSinceEpoch(json['end'] as int);

    if (json['type'] == 'stay') {
      return Stay(
        start: start,
        end: end,
        latitude: (json['latitude'] as num).toDouble(),
        longitude: (json['longitude'] as num).toDouble(),
        placeName: json['placeName'] as String?,
        estimatedPlaceName: json['estimatedPlaceName'] as String?,
      );
    }

    return Move(
      start: start,
      end: end,
      distanceMeters: (json['distanceMeters'] as num).toDouble(),
      transport: TransportMode.values
          .where((e) => e.name == json['transport'])
          .firstOrNull,
    );
  }
}
