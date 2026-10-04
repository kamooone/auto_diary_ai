/// 1日の行動を「滞在」と「移動」に分けたもの
sealed class TimelineItem {
  final DateTime start;
  final DateTime end;

  const TimelineItem({
    required this.start,
    required this.end,
  });

  Duration get duration => end.difference(start);
}

/// 同じ場所に一定時間とどまっていた区間
class Stay extends TimelineItem {
  final double latitude;
  final double longitude;

  /// 地名(取得できなかった場合はnull)
  final String? placeName;

  const Stay({
    required super.start,
    required super.end,
    required this.latitude,
    required this.longitude,
    this.placeName,
  });

  Stay copyWith({String? placeName}) {
    return Stay(
      start: start,
      end: end,
      latitude: latitude,
      longitude: longitude,
      placeName: placeName ?? this.placeName,
    );
  }
}

/// 滞在と滞在の間の移動区間
class Move extends TimelineItem {
  final double distanceMeters;

  const Move({
    required super.start,
    required super.end,
    required this.distanceMeters,
  });
}
