import 'package:auto_diary_ai/features/location/domain/entities/activity_segment.dart';
import 'package:auto_diary_ai/features/location/domain/entities/timeline_item.dart';
import 'package:auto_diary_ai/features/location/domain/entities/transport_mode.dart';
import 'package:auto_diary_ai/features/location/domain/services/transport_estimator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final estimator = TransportEstimator();

  DateTime at(int hour, int minute) => DateTime(2026, 1, 1, hour, minute);

  final move = Move(start: at(10, 0), end: at(10, 30), distanceMeters: 5000);

  ActivitySegment segment(DateTime start, DateTime end, ActivityType type) {
    return ActivitySegment(start: start, end: end, type: type);
  }

  test('行動の記録がなければ判断しない', () {
    expect(estimator.estimate(move, []), isNull);
  });

  test('最も長く続いていた行動を移動手段にする', () {
    final transport = estimator.estimate(move, [
      segment(at(10, 0), at(10, 5), ActivityType.walking),
      segment(at(10, 5), at(10, 25), ActivityType.automotive),
      segment(at(10, 25), at(10, 30), ActivityType.walking),
    ]);

    expect(transport, TransportMode.vehicle);
  });

  test('歩行と走行はどちらも徒歩として扱う', () {
    final transport = estimator.estimate(move, [
      segment(at(10, 0), at(10, 12), ActivityType.walking),
      segment(at(10, 12), at(10, 24), ActivityType.running),
      segment(at(10, 24), at(10, 30), ActivityType.cycling),
    ]);

    expect(transport, TransportMode.walk);
  });

  test('移動区間の外の行動は数えない', () {
    final transport = estimator.estimate(move, [
      segment(at(8, 0), at(10, 5), ActivityType.automotive),
      segment(at(10, 5), at(10, 30), ActivityType.cycling),
    ]);

    expect(transport, TransportMode.bicycle);
  });

  test('ほとんど静止の記録しかない場合は判断しない', () {
    final transport = estimator.estimate(move, [
      segment(at(10, 0), at(10, 25), ActivityType.stationary),
      segment(at(10, 25), at(10, 30), ActivityType.walking),
    ]);

    expect(transport, isNull);
  });
}
