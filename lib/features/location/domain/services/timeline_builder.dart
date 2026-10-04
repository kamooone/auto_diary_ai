import 'dart:math';
import '../entities/location.dart';
import '../entities/timeline_item.dart';

/// 位置情報の履歴を「滞在」と「移動」に要約する
class TimelineBuilder {
  // この範囲内にとどまっている間は同じ場所とみなす
  static const _stayRadiusMeters = 100.0;

  // この時間以上とどまった場合に滞在とみなす
  static const _minStayDuration = Duration(minutes: 5);

  // これ未満の移動は位置のぶれとみなして表示しない
  static const _minMoveMeters = 30.0;

  /// [until]を渡すと、最後にいた場所にその時刻までとどまっているものとして扱う
  List<TimelineItem> build(
    List<Location> locations, {
    DateTime? until,
  }) {
    if (locations.isEmpty) return [];

    final sorted = [...locations]
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    final clusters = _cluster(sorted);

    final items = <TimelineItem>[];
    final movePoints = <Location>[];
    Location? lastStayPoint;

    for (var i = 0; i < clusters.length; i++) {
      final cluster = clusters[i];
      final isLast = i == clusters.length - 1;

      final start = cluster.first.timestamp;
      var end = cluster.last.timestamp;
      if (isLast && until != null && until.isAfter(end)) {
        end = until;
      }

      if (end.difference(start) < _minStayDuration) {
        movePoints.addAll(cluster);
        continue;
      }

      final move = _move([
        if (lastStayPoint != null) lastStayPoint,
        ...movePoints,
        cluster.first,
      ]);
      if (move != null) items.add(move);

      items.add(
        Stay(
          start: start,
          end: end,
          latitude: _average(cluster.map((e) => e.latitude)),
          longitude: _average(cluster.map((e) => e.longitude)),
        ),
      );

      lastStayPoint = cluster.last;
      movePoints.clear();
    }

    if (movePoints.isNotEmpty) {
      final move = _move([
        if (lastStayPoint != null) lastStayPoint,
        ...movePoints,
      ]);
      if (move != null) items.add(move);
    }

    return items;
  }

  // 最初の点から一定範囲内にある連続した点をひとまとまりにする
  List<List<Location>> _cluster(List<Location> sorted) {
    final clusters = <List<Location>>[];
    var current = <Location>[sorted.first];

    for (final location in sorted.skip(1)) {
      if (_distance(current.first, location) <= _stayRadiusMeters) {
        current.add(location);
      } else {
        clusters.add(current);
        current = [location];
      }
    }
    clusters.add(current);

    return clusters;
  }

  Move? _move(List<Location> path) {
    if (path.length < 2) return null;

    var distance = 0.0;
    for (var i = 1; i < path.length; i++) {
      distance += _distance(path[i - 1], path[i]);
    }

    if (distance < _minMoveMeters) return null;

    return Move(
      start: path.first.timestamp,
      end: path.last.timestamp,
      distanceMeters: distance,
    );
  }

  double _average(Iterable<double> values) {
    return values.reduce((a, b) => a + b) / values.length;
  }

  // 2点間の距離(m)
  double _distance(Location a, Location b) {
    const earthRadius = 6371000.0;
    const toRadians = pi / 180;

    final dLat = (b.latitude - a.latitude) * toRadians;
    final dLng = (b.longitude - a.longitude) * toRadians;

    final h = sin(dLat / 2) * sin(dLat / 2) +
        cos(a.latitude * toRadians) *
            cos(b.latitude * toRadians) *
            sin(dLng / 2) *
            sin(dLng / 2);

    return 2 * earthRadius * asin(min(1.0, sqrt(h)));
  }
}
