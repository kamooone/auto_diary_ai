import '../entities/timeline_edit.dart';
import '../entities/timeline_item.dart';
import '../entities/transport_mode.dart';
import '../repositories/timeline_edit_repository.dart';
import '../services/timeline_edit_applier.dart';

class UpdateMoveTransportUseCase {

  final TimelineEditRepository repository;

  final TimelineEditApplier _applier = TimelineEditApplier();

  UpdateMoveTransportUseCase(
      this.repository,
      );

  /// 移動手段と、移動の説明(「〇〇さんの車で移動」など)を保存する
  /// どちらも指定しない場合は修正を取り消し、自動推定に戻す
  Future<void> execute(
      Move move, {
      TransportMode? transport,
      String? text,
      }) async {
    final edits = await repository.findOverlapping(move.start, move.end);
    final existing = _applier.match(move, edits);

    final trimmed = text?.trim();
    final transportText =
        (trimmed == null || trimmed.isEmpty) ? null : trimmed;

    if (transport == null && transportText == null) {
      final id = existing?.id;
      if (id != null) {
        await repository.delete(id);
      }
      return;
    }

    await repository.save(
      TimelineEdit(
        id: existing?.id,
        type: TimelineEditType.move,
        start: move.start,
        end: move.end,
        transport: transport,
        transportText: transportText,
      ),
    );
  }
}
