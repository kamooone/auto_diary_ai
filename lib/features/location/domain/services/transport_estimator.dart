import '../entities/activity_segment.dart';
import '../entities/timeline_item.dart';
import '../entities/transport_mode.dart';

/// OSが認識した行動から、移動区間の移動手段を推定する
class TransportEstimator {
  // 移動区間のうち、動いていた行動がこの割合に満たない場合は判断しない
  static const _minMovingRatio = 0.3;

  /// 移動区間で最も長く続いていた行動を移動手段とする(判断できない場合はnull)
  TransportMode? estimate(Move move, List<ActivitySegment> segments) {
    final durations = <TransportMode, Duration>{};
    var moving = Duration.zero;

    for (final segment in segments) {
      final mode = _mode(segment.type);
      if (mode == null) continue;

      final start = segment.start.isAfter(move.start) ? segment.start : move.start;
      final end = segment.end.isBefore(move.end) ? segment.end : move.end;
      final overlap = end.difference(start);
      if (overlap <= Duration.zero) continue;

      durations[mode] = (durations[mode] ?? Duration.zero) + overlap;
      moving += overlap;
    }

    if (durations.isEmpty) return null;
    if (moving.inMilliseconds < move.duration.inMilliseconds * _minMovingRatio) {
      return null;
    }

    return durations.entries
        .reduce((a, b) => a.value >= b.value ? a : b)
        .key;
  }

  TransportMode? _mode(ActivityType type) {
    return switch (type) {
      ActivityType.walking || ActivityType.running => TransportMode.walk,
      ActivityType.cycling => TransportMode.bicycle,
      // OSは車と電車を区別しない
      ActivityType.automotive => TransportMode.vehicle,
      ActivityType.stationary => null,
    };
  }
}
