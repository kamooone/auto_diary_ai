import '../entities/timeline_edit.dart';
import '../entities/timeline_item.dart';
import '../repositories/location_repository.dart';
import '../repositories/timeline_edit_repository.dart';

/// タイムラインの滞在・移動を削除する(Googleマップと同じように、データごと消す)
class DeleteTimelineItemUseCase {
  final LocationRepository locationRepository;

  final TimelineEditRepository timelineEditRepository;

  DeleteTimelineItemUseCase(
    this.locationRepository,
    this.timelineEditRepository,
  );

  Future<void> execute(TimelineItem item) async {
    // 記録をオフにしていた時間帯は、削除するデータがない
    if (item is RecordingOff) return;

    // 滞在は、その時間帯の位置をすべて消す。
    // 移動の両端は前後の滞在の位置なので、残す(間の位置だけを消す)
    await locationRepository.deleteLocations(
      item.start,
      item.end,
      includeEdges: item is Stay,
    );

    // 削除した項目に付けていた場所名・移動手段の修正も消す
    final edits = await timelineEditRepository.findOverlapping(
      item.start,
      item.end,
    );
    for (final edit in edits) {
      final id = edit.id;
      if (id == null || edit.type == TimelineEditType.deleted) continue;

      final isInside =
          !edit.start.isBefore(item.start) && !edit.end.isAfter(item.end);
      if (isInside) await timelineEditRepository.delete(id);
    }

    // 位置が残っていなくても(日をまたいだ滞在など)、同じ時間帯のものは表示しない
    await timelineEditRepository.save(
      TimelineEdit(
        type: TimelineEditType.deleted,
        start: item.start,
        end: item.end,
      ),
    );
  }
}
