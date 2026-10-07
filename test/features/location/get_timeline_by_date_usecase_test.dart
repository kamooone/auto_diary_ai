import 'package:auto_diary_ai/features/location/domain/entities/activity_segment.dart';
import 'package:auto_diary_ai/features/location/domain/entities/location.dart';
import 'package:auto_diary_ai/features/location/domain/entities/place_candidate.dart';
import 'package:auto_diary_ai/features/location/domain/entities/timeline_edit.dart';
import 'package:auto_diary_ai/features/location/domain/entities/timeline_item.dart';
import 'package:auto_diary_ai/features/location/domain/exceptions/place_search_exception.dart';
import 'package:auto_diary_ai/features/location/domain/repositories/activity_repository.dart';
import 'package:auto_diary_ai/features/location/domain/repositories/location_repository.dart';
import 'package:auto_diary_ai/features/location/domain/repositories/place_name_repository.dart';
import 'package:auto_diary_ai/features/location/domain/repositories/place_search_repository.dart';
import 'package:auto_diary_ai/features/location/domain/repositories/timeline_edit_repository.dart';
import 'package:auto_diary_ai/features/location/domain/repositories/timeline_snapshot_repository.dart';
import 'package:auto_diary_ai/features/location/domain/usecases/get_timeline_by_date_usecase.dart';
import 'package:flutter_test/flutter_test.dart';

// 過去の日(保存の対象)
final day = DateTime(2026, 1, 1);

Location point(int hour, int minute, double latitude) {
  return Location(
    id: 0,
    latitude: latitude,
    longitude: 139.0,
    timestamp: DateTime(2026, 1, 1, hour, minute),
  );
}

class FakeLocationRepository implements LocationRepository {
  List<Location> locations = [point(9, 0, 35.0), point(11, 0, 35.0001)];

  Location? previous;
  Location? next;

  @override
  Future<List<Location>> getLocationsByDate(DateTime date) async => locations;

  @override
  Future<Location?> getLastLocationBefore(DateTime time) async => previous;

  @override
  Future<Location?> getFirstLocationFrom(DateTime time) async => next;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakePlaceNameRepository implements PlaceNameRepository {
  String? name = '東京都千代田区';
  int callCount = 0;

  @override
  Future<String?> getPlaceName(double latitude, double longitude) async {
    callCount++;
    return name;
  }
}

class FakePlaceSearchRepository implements PlaceSearchRepository {
  bool shouldFail = false;
  int callCount = 0;

  @override
  Future<List<List<PlaceCandidate>>> findNearby(
    List<Coordinate> coordinates,
  ) async {
    callCount++;
    if (shouldFail) throw PlaceSearchException('failed');

    return [
      for (final _ in coordinates)
        const [PlaceCandidate(name: 'カフェA', distanceMeters: 10)],
    ];
  }
}

class FakeActivityRepository implements ActivityRepository {
  @override
  Future<List<ActivitySegment>> getActivities(
    DateTime start,
    DateTime end,
  ) async =>
      [];
}

class FakeTimelineEditRepository implements TimelineEditRepository {
  List<TimelineEdit> edits = [];

  @override
  Future<List<TimelineEdit>> findOverlapping(
    DateTime start,
    DateTime end,
  ) async =>
      edits;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeTimelineSnapshotRepository implements TimelineSnapshotRepository {
  List<TimelineItem>? saved;
  String? savedSignature;

  @override
  Future<List<TimelineItem>?> find(
    DateTime date, {
    required String signature,
  }) async {
    return savedSignature == signature ? saved : null;
  }

  @override
  Future<void> save(
    DateTime date,
    List<TimelineItem> items, {
    required String signature,
  }) async {
    saved = items;
    savedSignature = signature;
  }
}

void main() {
  late FakeLocationRepository locations;
  late FakePlaceNameRepository placeNames;
  late FakePlaceSearchRepository placeSearch;
  late FakeTimelineEditRepository edits;
  late FakeTimelineSnapshotRepository snapshots;
  late GetTimelineByDateUseCase useCase;

  setUp(() {
    locations = FakeLocationRepository();
    placeNames = FakePlaceNameRepository();
    placeSearch = FakePlaceSearchRepository();
    edits = FakeTimelineEditRepository();
    snapshots = FakeTimelineSnapshotRepository();

    useCase = GetTimelineByDateUseCase(
      repository: locations,
      placeNameRepository: placeNames,
      timelineEditRepository: edits,
      placeSearchRepository: placeSearch,
      activityRepository: FakeActivityRepository(),
      timelineSnapshotRepository: snapshots,
    );
  });

  test('過去の日は計算結果を保存し、次回は問い合わせずに表示する', () async {
    final first = await useCase.execute(day);
    final second = await useCase.execute(day);

    expect(placeNames.callCount, 1);
    expect(placeSearch.callCount, 1);

    for (final items in [first, second]) {
      final stay = items.single as Stay;
      expect(stay.placeName, '東京都千代田区');
      expect(stay.displayName, 'カフェA');
    }
  });

  test('地名を取得できなかった場合は保存しない', () async {
    placeNames.name = null;

    await useCase.execute(day);

    expect(snapshots.saved, isNull);
  });

  test('施設を検索できなかった場合は保存せず、地名だけで表示する', () async {
    placeSearch.shouldFail = true;

    final items = await useCase.execute(day);

    expect(snapshots.saved, isNull);
    expect((items.single as Stay).displayName, '東京都千代田区');
  });

  test('施設を当てはめない場合は保存しない', () async {
    await useCase.execute(day, estimatePlaces: false);

    expect(snapshots.saved, isNull);
    expect(placeSearch.callCount, 0);
  });

  test('保存後に位置情報が増えた場合は計算し直す', () async {
    await useCase.execute(day);

    locations.locations = [...locations.locations, point(11, 30, 35.0001)];
    final items = await useCase.execute(day);

    expect(placeNames.callCount, 2);
    expect((items.single as Stay).end, DateTime(2026, 1, 1, 11, 30));
  });

  test('前の日の最後の位置にいた状態で、0時を迎えたものとして扱う', () async {
    locations.previous = Location(
      id: 0,
      latitude: 35.0,
      longitude: 139.0,
      timestamp: DateTime(2025, 12, 31, 22, 0),
    );

    final stay = (await useCase.execute(day)).single as Stay;

    expect(stay.start, DateTime(2026, 1, 1, 0, 0));
    expect(stay.end, DateTime(2026, 1, 1, 11, 0));
  });

  test('前の日の位置が古すぎる場合は引き継がない', () async {
    locations.previous = Location(
      id: 0,
      latitude: 35.0,
      longitude: 139.0,
      timestamp: DateTime(2025, 12, 20, 22, 0),
    );

    final stay = (await useCase.execute(day)).single as Stay;

    expect(stay.start, DateTime(2026, 1, 1, 9, 0));
  });

  test('保存後に翌日の位置が届いた場合は計算し直す', () async {
    await useCase.execute(day);

    locations.next = Location(
      id: 0,
      latitude: 35.0001,
      longitude: 139.0,
      timestamp: DateTime(2026, 1, 2, 8, 0),
    );
    final stay = (await useCase.execute(day)).single as Stay;

    expect(placeNames.callCount, 2);
    expect(stay.end, DateTime(2026, 1, 1, 23, 59, 59));
  });

  test('保存した結果にも、ユーザーの修正を当てはめる', () async {
    await useCase.execute(day);

    edits.edits = [
      TimelineEdit(
        type: TimelineEditType.stay,
        start: DateTime(2026, 1, 1, 9, 0),
        end: DateTime(2026, 1, 1, 11, 0),
        placeName: '自宅',
      ),
    ];

    final stay = (await useCase.execute(day)).single as Stay;

    expect(stay.displayName, '自宅');
    expect(stay.isPlaceNameEdited, isTrue);
    expect(placeNames.callCount, 1);
  });

  test('今日のタイムラインは保存しない', () async {
    final now = DateTime.now();
    locations.locations = [
      Location(
        id: 0,
        latitude: 35.0,
        longitude: 139.0,
        timestamp: now.subtract(const Duration(minutes: 30)),
      ),
    ];

    await useCase.execute(now);

    expect(snapshots.saved, isNull);
  });
}
