import '../entities/timeline_edit.dart';
import '../entities/timeline_item.dart';
import '../repositories/timeline_edit_repository.dart';
import '../services/timeline_edit_applier.dart';

class UpdateStayPlaceNameUseCase {

  final TimelineEditRepository repository;

  final TimelineEditApplier _applier = TimelineEditApplier();

  UpdateStayPlaceNameUseCase(
      this.repository,
      );

  /// 滞在の場所名を保存する
  /// [placeName]がnullまたは空の場合は修正を取り消し、自動で取得した場所名に戻す
  Future<void> execute(
      Stay stay,
      String? placeName,
      ) async {
    final edits = await repository.findOverlapping(stay.start, stay.end);
    final existing = _applier.match(stay, edits);

    final name = placeName?.trim();

    if (name == null || name.isEmpty) {
      final id = existing?.id;
      if (id != null) {
        await repository.delete(id);
      }
      return;
    }

    await repository.save(
      TimelineEdit(
        id: existing?.id,
        type: TimelineEditType.stay,
        start: stay.start,
        end: stay.end,
        placeName: name,
      ),
    );
  }
}
