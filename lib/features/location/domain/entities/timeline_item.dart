import 'transport_mode.dart';

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

  /// 場所名
  /// ユーザーが入力したもの、または座標から取得した住所(取得できなかった場合はnull)
  final String? placeName;

  /// 周辺の施設から推定した、訪れた施設の名前(近くに施設がない場合はnull)
  final String? estimatedPlaceName;

  /// 場所名がユーザーの入力したものかどうか
  final bool isPlaceNameEdited;

  const Stay({
    required super.start,
    required super.end,
    required this.latitude,
    required this.longitude,
    this.placeName,
    this.estimatedPlaceName,
    this.isPlaceNameEdited = false,
  });

  /// ユーザーが確認していない滞在で、施設を推定で当てはめているかどうか
  bool get isPlaceEstimated => !isPlaceNameEdited && estimatedPlaceName != null;

  /// 表示する場所名
  /// ユーザーが入力したもの、推定した施設、住所の順に優先する
  String? get displayName {
    return isPlaceEstimated ? estimatedPlaceName : placeName;
  }

  Stay copyWith({
    String? placeName,
    String? estimatedPlaceName,
    bool? isPlaceNameEdited,
  }) {
    return Stay(
      start: start,
      end: end,
      latitude: latitude,
      longitude: longitude,
      placeName: placeName ?? this.placeName,
      estimatedPlaceName: estimatedPlaceName ?? this.estimatedPlaceName,
      isPlaceNameEdited: isPlaceNameEdited ?? this.isPlaceNameEdited,
    );
  }
}

/// 滞在と滞在の間の移動区間
class Move extends TimelineItem {
  final double distanceMeters;

  /// 移動手段(分からない場合はnull)
  final TransportMode? transport;

  /// 移動の説明(「〇〇さんの車で移動」など、ユーザーが自由に書いた文。なければnull)
  final String? transportText;

  /// 移動手段や説明をユーザーが修正したかどうか(falseの場合は自動推定)
  final bool isTransportEdited;

  const Move({
    required super.start,
    required super.end,
    required this.distanceMeters,
    this.transport,
    this.transportText,
    this.isTransportEdited = false,
  });

  Move copyWith({
    TransportMode? transport,
    String? transportText,
    bool? isTransportEdited,
  }) {
    return Move(
      start: start,
      end: end,
      distanceMeters: distanceMeters,
      transport: transport ?? this.transport,
      transportText: transportText ?? this.transportText,
      isTransportEdited: isTransportEdited ?? this.isTransportEdited,
    );
  }
}
