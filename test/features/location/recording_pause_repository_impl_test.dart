import 'package:auto_diary_ai/features/location/data/datasources/recording_state_datasource.dart';
import 'package:auto_diary_ai/features/location/data/repositories/recording_pause_repository_impl.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeRecordingStateDataSource extends RecordingStateDataSource {
  List<({bool enabled, DateTime timestamp})> history = [];

  @override
  Future<List<({bool enabled, DateTime timestamp})>> getHistory() async {
    return history;
  }
}

void main() {
  late FakeRecordingStateDataSource dataSource;
  late RecordingPauseRepositoryImpl repository;

  DateTime at(int day, int hour) => DateTime(2026, 1, day, hour);

  setUp(() {
    dataSource = FakeRecordingStateDataSource();
    repository = RecordingPauseRepositoryImpl(dataSource);
  });

  test('オフにした時刻から、次にオンにした時刻までを1つの期間にする', () async {
    dataSource.history = [
      (enabled: false, timestamp: at(1, 0)),
      (enabled: true, timestamp: at(1, 9)),
      (enabled: false, timestamp: at(1, 18)),
      (enabled: true, timestamp: at(2, 9)),
    ];

    final pauses = await repository.getPauses(at(1, 0), at(3, 0));

    expect(pauses, hasLength(2));
    expect(pauses[0].start, at(1, 0));
    expect(pauses[0].end, at(1, 9));
    expect(pauses[1].start, at(1, 18));
    expect(pauses[1].end, at(2, 9));
  });

  test('今もオフのままの場合は、終わりのない期間にする', () async {
    dataSource.history = [
      (enabled: true, timestamp: at(1, 9)),
      (enabled: false, timestamp: at(1, 18)),
    ];

    final pauses = await repository.getPauses(at(1, 0), at(3, 0));

    expect(pauses.single.start, at(1, 18));
    expect(pauses.single.end, isNull);
  });

  test('指定した範囲に重ならない期間は返さない', () async {
    dataSource.history = [
      (enabled: false, timestamp: at(1, 0)),
      (enabled: true, timestamp: at(1, 9)),
      (enabled: false, timestamp: at(5, 0)),
      (enabled: true, timestamp: at(5, 9)),
    ];

    final pauses = await repository.getPauses(at(2, 0), at(3, 0));

    expect(pauses, isEmpty);
  });

  test('切り替えの記録がない場合は、オフにしていた期間はない', () async {
    expect(await repository.getPauses(at(1, 0), at(3, 0)), isEmpty);
  });
}
