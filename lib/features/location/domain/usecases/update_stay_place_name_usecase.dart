import '../entities/registered_place.dart';
import '../entities/timeline_edit.dart';
import '../entities/timeline_item.dart';
import '../repositories/registered_place_repository.dart';
import '../repositories/timeline_edit_repository.dart';
import '../services/registered_place_finder.dart';
import '../services/timeline_edit_applier.dart';

class UpdateStayPlaceNameUseCase {

  final TimelineEditRepository repository;

  final RegisteredPlaceRepository registeredPlaceRepository;

  final TimelineEditApplier _applier = TimelineEditApplier();

  final RegisteredPlaceFinder _finder = RegisteredPlaceFinder();

  UpdateStayPlaceNameUseCase(
      this.repository,
      this.registeredPlaceRepository,
      );

  /// 滞在の場所名を保存する
  ///
  /// 保存した場所名は、同じ場所を訪れたときにも表示する(場所として登録する)。
  /// [placeName]がnullまたは空の場合は修正と登録を取り消し、自動で取得した場所名に戻す
  Future<void> execute(
      Stay stay,
      String? placeName,
      ) async {
    final edits = await repository.findOverlapping(stay.start, stay.end);
    final existing = _applier.match(stay, edits);

    final registered = _finder.find(
      stay,
      await registeredPlaceRepository.getAll(),
    );

    final name = placeName?.trim();

    if (name == null || name.isEmpty) {
      final id = existing?.id;
      if (id != null) {
        await repository.delete(id);
      }

      final registeredId = registered?.id;
      if (registeredId != null) {
        await registeredPlaceRepository.delete(registeredId);
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

    // 登録済みの場所の近くなら名前を更新し、そうでなければ新しく登録する
    await registeredPlaceRepository.save(
      registered?.copyWith(name: name) ??
          RegisteredPlace(
            latitude: stay.latitude,
            longitude: stay.longitude,
            name: name,
          ),
    );
  }
}
