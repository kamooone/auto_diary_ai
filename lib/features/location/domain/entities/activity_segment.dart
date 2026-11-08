/// OSが認識した行動の種類
enum ActivityType { stationary, walking, running, cycling, automotive }

/// ある行動が続いていた区間
class ActivitySegment {
  final DateTime start;
  final DateTime end;
  final ActivityType type;

  const ActivitySegment({
    required this.start,
    required this.end,
    required this.type,
  });
}
