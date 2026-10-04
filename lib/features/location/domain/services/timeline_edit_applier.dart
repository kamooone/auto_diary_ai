import '../entities/timeline_edit.dart';
import '../entities/timeline_item.dart';

/// ユーザーの修正を、計算し直したタイムラインに当てはめる
class TimelineEditApplier {
  List<TimelineItem> apply(
    List<TimelineItem> items,
    List<TimelineEdit> edits,
  ) {
    return [
      for (final item in items) _applyTo(item, match(item, edits)),
    ];
  }

  /// 滞在・移動に対応する修正を探す(なければnull)
  ///
  /// 後から届いた位置情報で滞在の開始・終了時刻が多少ずれても対応づけられるよう、
  /// 時間帯の重なりが最も大きいものを選ぶ。重なりが短い方の半分に満たない場合は
  /// 別の滞在・移動とみなす。
  TimelineEdit? match(TimelineItem item, List<TimelineEdit> edits) {
    final type = switch (item) {
      Stay() => TimelineEditType.stay,
      Move() => TimelineEditType.move,
    };

    TimelineEdit? best;
    var bestOverlap = Duration.zero;

    for (final edit in edits) {
      if (edit.type != type) continue;

      final overlap = _overlap(item.start, item.end, edit.start, edit.end);
      if (overlap <= Duration.zero) continue;

      final editDuration = edit.end.difference(edit.start);
      final shorter =
          item.duration < editDuration ? item.duration : editDuration;
      if (overlap * 2 < shorter) continue;

      if (overlap > bestOverlap) {
        best = edit;
        bestOverlap = overlap;
      }
    }

    return best;
  }

  TimelineItem _applyTo(TimelineItem item, TimelineEdit? edit) {
    if (edit == null) return item;

    return switch (item) {
      Stay() => edit.placeName == null
          ? item
          : item.copyWith(
              placeName: edit.placeName,
              isPlaceNameEdited: true,
            ),
      Move() => edit.transport == null && edit.transportText == null
          ? item
          : item.copyWith(
              transport: edit.transport,
              transportText: edit.transportText,
              isTransportEdited: true,
            ),
    };
  }

  Duration _overlap(
    DateTime aStart,
    DateTime aEnd,
    DateTime bStart,
    DateTime bEnd,
  ) {
    final start = aStart.isAfter(bStart) ? aStart : bStart;
    final end = aEnd.isBefore(bEnd) ? aEnd : bEnd;
    return end.difference(start);
  }
}
