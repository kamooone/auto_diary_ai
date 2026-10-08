/// 行動履歴の記録をオフにしていた期間
class RecordingPause {
  final DateTime start;

  /// 記録を再開した時刻(今もオフのままの場合はnull)
  final DateTime? end;

  const RecordingPause({
    required this.start,
    this.end,
  });

  /// [from]から[to]までの間に、オフにしていた時間が含まれるかどうか
  bool overlaps(DateTime from, DateTime to) {
    final end = this.end;
    return start.isBefore(to) && (end == null || end.isAfter(from));
  }
}
