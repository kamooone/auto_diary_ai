import '../../../location/domain/entities/timeline_item.dart';

/// 行動履歴(滞在した場所と移動)を、AIに渡す文章にする
class TimelineText {
  const TimelineText._();

  /// [addressStays]に入れた滞在だけ、住所(住所が分からないときは座標)も渡す。
  /// 入れなかった滞在は、住所も座標も渡さない(利用者が、送ると決めたものだけを送る)
  static String format(
    List<TimelineItem> timeline, {
    Set<TimelineItem> addressStays = const {},
  }) {
    return timeline
        .map((e) {
          final time = "${_time(e.start)}〜${_time(e.end)}";

          return switch (e) {
            Stay() =>
              "$time 滞在: ${_place(e, withAddress: addressStays.contains(e))}",
            Move() =>
              "$time 移動${_transport(e)}: 約${_distance(e.distanceMeters)}",
            RecordingOff() => "$time 記録なし",
          };
        })
        .join("\n");
  }

  /// 住所(分からないときは、座標)。AIに渡す前に、利用者に見せるときにも使う
  static String addressOf(Stay stay) {
    return stay.placeName ??
        "緯度${stay.latitude.toStringAsFixed(4)} 経度${stay.longitude.toStringAsFixed(4)}付近";
  }

  // 滞在した場所(ユーザーが確認したものと、周辺の施設からの推定を区別して伝える)
  static String _place(Stay stay, {required bool withAddress}) {
    // ユーザーが書いた・登録した名前は、そのまま伝える(住所は含まない)
    if (stay.isPlaceNameEdited) return stay.placeName ?? "場所の情報なし";

    if (stay.isPlaceEstimated) {
      return withAddress
          ? "${stay.estimatedPlaceName}(推定。住所: ${addressOf(stay)})"
          : "${stay.estimatedPlaceName}(推定)";
    }

    // 施設の推定がなく、住所や座標だけが分かっているとき
    return withAddress ? addressOf(stay) : "場所の情報なし";
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
