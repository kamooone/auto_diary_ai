import 'package:flutter/material.dart';
import '../../domain/entities/timeline_item.dart';
import '../../domain/entities/transport_mode.dart';

/// タイムライン(滞在と移動)の表示用の文言
class TimelineFormatter {
  static String time(DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return "$hour:$minute";
  }

  static String timeRange(TimelineItem item) {
    return "${time(item.start)}〜${time(item.end)}";
  }

  static String duration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    return hours > 0 ? "$hours時間$minutes分" : "$minutes分";
  }

  static String distance(double meters) {
    return meters >= 1000
        ? "${(meters / 1000).toStringAsFixed(1)}km"
        : "${meters.round()}m";
  }

  /// 滞在の場所名(推定の場合はその旨を添える)
  static String stayTitle(Stay stay) {
    final name = stay.displayName ?? "場所名を取得できませんでした";
    return stay.isPlaceEstimated ? "$name（推定）" : name;
  }

  static String moveTitle(Move move) {
    final distanceText = "約${distance(move.distanceMeters)}";

    // ユーザーが書いた説明があれば、それをそのまま表示する
    final text = move.transportText;
    if (text != null) return "$text $distanceText";

    final transport = move.transport;
    if (transport == null) return "移動 $distanceText";

    return move.isTransportEdited
        ? "${transport.label}で移動 $distanceText"
        : "${transport.label}で移動（推定） $distanceText";
  }

  static IconData transportIcon(TransportMode? transport) {
    return switch (transport) {
      TransportMode.walk => Icons.directions_walk,
      TransportMode.bicycle => Icons.directions_bike,
      TransportMode.vehicle => Icons.commute,
      TransportMode.car => Icons.directions_car,
      TransportMode.bus => Icons.directions_bus,
      TransportMode.train => Icons.train,
      TransportMode.other => Icons.more_horiz,
      null => Icons.more_vert,
    };
  }
}
