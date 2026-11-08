import '../../domain/entities/recording_pause.dart';
import '../../domain/repositories/recording_pause_repository.dart';
import '../datasources/recording_state_datasource.dart';

class RecordingPauseRepositoryImpl implements RecordingPauseRepository {
  final RecordingStateDataSource dataSource;

  RecordingPauseRepositoryImpl(this.dataSource);

  @override
  Future<List<RecordingPause>> getPauses(DateTime from, DateTime to) async {
    final history = await dataSource.getHistory();

    // オフにした時刻から、次にオンにした時刻までを1つの期間にする
    final pauses = <RecordingPause>[];
    DateTime? pausedAt;

    for (final record in history) {
      if (!record.enabled) {
        pausedAt ??= record.timestamp;
      } else if (pausedAt != null) {
        pauses.add(RecordingPause(start: pausedAt, end: record.timestamp));
        pausedAt = null;
      }
    }

    if (pausedAt != null) {
      pauses.add(RecordingPause(start: pausedAt));
    }

    return [
      for (final pause in pauses)
        if (pause.overlaps(from, to)) pause,
    ];
  }
}
