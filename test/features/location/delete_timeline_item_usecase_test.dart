import 'package:auto_diary_ai/features/location/domain/entities/timeline_edit.dart';
import 'package:auto_diary_ai/features/location/domain/entities/timeline_item.dart';
import 'package:auto_diary_ai/features/location/domain/repositories/location_repository.dart';
import 'package:auto_diary_ai/features/location/domain/repositories/timeline_edit_repository.dart';
import 'package:auto_diary_ai/features/location/domain/usecases/delete_timeline_item_usecase.dart';
import 'package:flutter_test/flutter_test.dart';

class _Locations implements LocationRepository {
  final deleted = <({DateTime start, DateTime end, bool includeEdges})>[];

  @override
  Future<void> deleteLocations(
    DateTime start,
    DateTime end, {
    bool includeEdges = true,
  }) async {
    deleted.add((start: start, end: end, includeEdges: includeEdges));
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Edits implements TimelineEditRepository {
  final saved = <TimelineEdit>[];
  final deletedIds = <int>[];
  List<TimelineEdit> existing = [];

  @override
  Future<List<TimelineEdit>> findOverlapping(DateTime a, DateTime b) async =>
      existing;

  @override
  Future<void> save(TimelineEdit edit) async => saved.add(edit);

  @override
  Future<void> delete(int id) async => deletedIds.add(id);
}

void main() {
  late _Locations locations;
  late _Edits edits;
  late DeleteTimelineItemUseCase useCase;

  final start = DateTime(2026, 1, 1, 9, 0);
  final end = DateTime(2026, 1, 1, 10, 0);

  setUp(() {
    locations = _Locations();
    edits = _Edits();
    useCase = DeleteTimelineItemUseCase(locations, edits);
  });

  test('滞在は、両端を含めて位置を削除し、削除した時間帯を記録する', () async {
    await useCase.execute(
      Stay(start: start, end: end, latitude: 35, longitude: 139),
    );

    expect(locations.deleted.single.includeEdges, isTrue);
    expect(locations.deleted.single.start, start);
    expect(edits.saved.single.type, TimelineEditType.deleted);
    expect(edits.saved.single.start, start);
    expect(edits.saved.single.end, end);
  });

  test('移動は、両端(前後の滞在の位置)を残して削除する', () async {
    await useCase.execute(Move(start: start, end: end, distanceMeters: 500));

    expect(locations.deleted.single.includeEdges, isFalse);
    expect(edits.saved.single.type, TimelineEditType.deleted);
  });

  test('削除した滞在に付けていた場所名の修正も消す', () async {
    edits.existing = [
      TimelineEdit(
        id: 7,
        type: TimelineEditType.stay,
        start: start,
        end: end,
        placeName: '自宅',
      ),
      // 時間帯がはみ出すものは、別の項目の修正なので残す
      TimelineEdit(
        id: 8,
        type: TimelineEditType.stay,
        start: end,
        end: end.add(const Duration(hours: 1)),
      ),
    ];

    await useCase.execute(
      Stay(start: start, end: end, latitude: 35, longitude: 139),
    );

    expect(edits.deletedIds, [7]);
  });

  test('記録をオフにしていた時間帯は何もしない', () async {
    await useCase.execute(RecordingOff(start: start, end: end));

    expect(locations.deleted, isEmpty);
    expect(edits.saved, isEmpty);
  });
}
