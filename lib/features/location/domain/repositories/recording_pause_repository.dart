import '../entities/recording_pause.dart';

abstract class RecordingPauseRepository {
  /// [from]から[to]までの間に重なる、記録をオフにしていた期間(古い順)
  Future<List<RecordingPause>> getPauses(DateTime from, DateTime to);
}
