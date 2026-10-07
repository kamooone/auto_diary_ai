import 'dart:math';
import '../entities/location.dart';
import '../entities/timeline_item.dart';
import '../entities/transport_mode.dart';

/// 位置情報の履歴を「滞在」と「移動」に要約する
class TimelineBuilder {
  // この範囲内にとどまっている間は同じ場所とみなす
  static const _stayRadiusMeters = 100.0;

  // この時間以上とどまった場合に滞在とみなす
  static const _minStayDuration = Duration(minutes: 5);

  // これ未満の移動は位置のぶれとみなして表示しない
  static const _minMoveMeters = 30.0;

  // 滞在の途中に入った位置のぶれとみなす条件
  // (元の場所に戻るまでの点の数がこれ以下で、滞在場所からこの距離以内にある)
  static const _maxDriftPoints = 3;
  static const _maxDriftMeters = 400.0;

  // 移動手段を推定するときの速度の境目(km/h)
  static const _walkMaxKmh = 7.0;
  static const _bicycleMaxKmh = 20.0;

  // これより遅い区間は立ち止まっているとみなし、速度の計算に含めない
  static const _minMovingKmh = 1.0;

  // 点の間隔がこれより長い区間は記録が途切れているとみなし、速度の計算に含めない
  static const _maxSegmentDuration = Duration(minutes: 10);

  /// [locations]はタイムラインを作る日の位置情報
  ///
  /// 位置情報は移動したときにしか記録されないため、その日の記録だけでは
  /// 「前の晩から同じ場所にいた」ことが分からない。前後の日の位置を渡すと、
  /// 日をまたいだ滞在として扱う。
  ///
  /// - [dayStart]と[previous]: [previous](その日より前の最後の位置)にいた状態で
  ///   [dayStart](その日の0時)を迎えたものとして扱う
  /// - [dayEnd]と[next]: [next](その日より後の最初の位置)がその日の最後の位置の近くなら、
  ///   [dayEnd](その日の終わり)までそこにとどまっていたものとして扱う
  /// - [until]: 最後にいた場所に、その時刻までとどまっているものとして扱う(今日の場合)
  List<TimelineItem> build(
    List<Location> locations, {
    DateTime? until,
    DateTime? dayStart,
    Location? previous,
    DateTime? dayEnd,
    Location? next,
  }) {
    final sorted = [...locations]
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    if (previous != null && dayStart != null) {
      sorted.insert(0, _at(previous, dayStart));
    }

    if (sorted.isEmpty) return [];

    if (next != null &&
        dayEnd != null &&
        _distance(sorted.last, next) <= _stayRadiusMeters) {
      sorted.add(_at(sorted.last, dayEnd));
    }

    final clusters = _mergeDrift(_cluster(sorted));

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

  // 同じ場所の、別の時刻の位置
  Location _at(Location location, DateTime time) {
    return Location(
      id: location.id,
      latitude: location.latitude,
      longitude: location.longitude,
      timestamp: time,
    );
  }

  /// 滞在の途中に入った位置のぶれを取り除き、前後を1つのまとまりにつなぐ
  ///
  /// 室内ではGPSがときどき大きくずれた位置を返す。そのままだと、ずれた点の前後で
  /// 滞在が途切れ、ずっと移動していたように見えてしまう。
  /// 「少数の点が近くに出て、すぐ元の場所に戻っている」場合は、ぶれとみなす。
  List<List<Location>> _mergeDrift(List<List<Location>> clusters) {
    final merged = <List<Location>>[];

    var i = 0;
    while (i < clusters.length) {
      var current = clusters[i];
      var next = i + 1;

      while (true) {
        final resumeIndex = _findResume(clusters, current, next);
        if (resumeIndex == null) break;

        // 間の点(ぶれ)は捨て、元の場所に戻った後の点をつなげる
        current = [...current, ...clusters[resumeIndex]];
        next = resumeIndex + 1;
      }

      merged.add(current);
      i = next;
    }

    return merged;
  }

  /// [from]以降で、[current]と同じ場所に戻っているまとまりの位置を探す
  /// 間にあるものがすべて位置のぶれとみなせる場合だけ返す
  int? _findResume(
    List<List<Location>> clusters,
    List<Location> current,
    int from,
  ) {
    final anchor = current.first;

    // 元の場所に戻るまでに記録された点の数
    // (実際に出かけた場合は、移動中の点が続けて記録されるため多くなる)
    var pointCount = 0;

    for (var j = from; j < clusters.length; j++) {
      if (_distance(anchor, clusters[j].first) <= _stayRadiusMeters) {
        return j;
      }

      pointCount += clusters[j].length;

      final isDrift = pointCount <= _maxDriftPoints &&
          clusters[j].every((e) => _distance(anchor, e) <= _maxDriftMeters);
      if (!isDrift) return null;
    }

    return null;
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
      transport: _estimateTransport(path),
    );
  }

  /// 実際に動いていた区間の速度から移動手段を推定する(判断できない場合はnull)
  TransportMode? _estimateTransport(List<Location> path) {
    var movingMeters = 0.0;
    var movingSeconds = 0.0;

    for (var i = 1; i < path.length; i++) {
      final elapsed = path[i].timestamp.difference(path[i - 1].timestamp);
      if (elapsed <= Duration.zero || elapsed > _maxSegmentDuration) continue;

      final meters = _distance(path[i - 1], path[i]);
      final seconds = elapsed.inMilliseconds / 1000;

      if (meters / seconds * 3.6 < _minMovingKmh) continue;

      movingMeters += meters;
      movingSeconds += seconds;
    }

    if (movingSeconds == 0) return null;

    final kmh = movingMeters / movingSeconds * 3.6;

    if (kmh < _walkMaxKmh) return TransportMode.walk;
    if (kmh < _bicycleMaxKmh) return TransportMode.bicycle;
    return TransportMode.vehicle;
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
