import '../../../location/domain/entities/timeline_item.dart';

/// 行動履歴(滞在した場所と移動)を、AIに渡す文章にする
class TimelineText {
  const TimelineText._();

  static String format(List<TimelineItem> timeline) {
    return timeline
        .map((e) {
          final time = "${_time(e.start)}〜${_time(e.end)}";

          return switch (e) {
            Stay() => "$time 滞在: ${_place(e)}",
            Move() =>
              "$time 移動${_transport(e)}: 約${_distance(e.distanceMeters)}",
            RecordingOff() => "$time 記録なし",
          };
        })
        .join("\n");
  }

  // 滞在した場所(ユーザーが確認したものと、周辺の施設からの推定を区別して伝える)
  static String _place(Stay stay) {
    final address =
        stay.placeName ??
        "緯度${stay.latitude.toStringAsFixed(4)} 経度${stay.longitude.toStringAsFixed(4)}付近";

    if (!stay.isPlaceEstimated) return address;

    return "${stay.estimatedPlaceName}(推定。住所: $address)";
  }

  // 移動手段(ユーザーが選んだものと、速度からの推定を区別して伝える)
  static String _transport(Move move) {
    // ユーザーが書いた説明があれば、それをそのまま伝える
    final text = move.transportText;
    if (text != null) return "($text)";

    final transport = move.transport;
    if (transport == null) return "";

    return move.isTransportEdited
        ? "(${transport.label})"
        : "(${transport.label}と推定)";
  }

  static String _time(DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return "$hour:$minute";
  }

  static String _distance(double meters) {
    return meters >= 1000
        ? "${(meters / 1000).toStringAsFixed(1)}km"
        : "${meters.round()}m";
  }
}
