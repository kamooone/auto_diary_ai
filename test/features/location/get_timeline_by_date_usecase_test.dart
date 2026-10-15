import 'dart:async';

import 'package:auto_diary_ai/features/location/domain/entities/activity_segment.dart';
import 'package:auto_diary_ai/features/location/domain/entities/location.dart';
import 'package:auto_diary_ai/features/location/domain/entities/place_candidate.dart';
import 'package:auto_diary_ai/features/location/domain/entities/recording_pause.dart';
import 'package:auto_diary_ai/features/location/domain/entities/registered_place.dart';
import 'package:auto_diary_ai/features/location/domain/entities/timeline_edit.dart';
import 'package:auto_diary_ai/features/location/domain/entities/timeline_item.dart';
import 'package:auto_diary_ai/features/location/domain/exceptions/place_search_exception.dart';
import 'package:auto_diary_ai/features/location/domain/repositories/activity_repository.dart';
import 'package:auto_diary_ai/features/location/domain/repositories/location_repository.dart';
import 'package:auto_diary_ai/features/location/domain/repositories/place_name_repository.dart';
import 'package:auto_diary_ai/features/location/domain/repositories/place_search_repository.dart';
import 'package:auto_diary_ai/features/location/domain/repositories/recording_pause_repository.dart';
import 'package:auto_diary_ai/features/location/domain/repositories/registered_place_repository.dart';
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

/// 問い合わせに時間がかかり、同時に何件問い合わせたかを記録する
class SlowPlaceNameRepository implements PlaceNameRepository {
  int running = 0;
  int maxRunning = 0;

  @override
  Future<String?> getPlaceName(double latitude, double longitude) async {
    running++;
    if (running > maxRunning) maxRunning = running;
    await Future<void>.delayed(const Duration(milliseconds: 20));
    running--;
    return '地名$latitude';
  }
}

/// 問い合わせが終わらない
class HangingPlaceNameRepository implements PlaceNameRepository {
  @override
  Future<String?> getPlaceName(double latitude, double longitude) {
    return Completer<String?>().future;
  }
}

class FakePlaceSearchRepository implements PlaceSearchRepository {
  bool shouldFail = false;

  @override
  Future<List<PlaceCandidate>> search(Coordinate coordinate) async => [];

  /// 検索できないことにする場所の番号
  Set<int> failingIndexes = {};

  int callCount = 0;

  @override
  Future<List<List<PlaceCandidate>?>> findNearby(
    List<Coordinate> coordinates,
  ) async {
    callCount++;
    if (shouldFail) throw PlaceSearchException('failed');

    return [
      for (var i = 0; i < coordinates.length; i++)
        failingIndexes.contains(i)
            ? null
            : const [PlaceCandidate(name: 'カフェA', distanceMeters: 10)],
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

class FakeRecordingPauseRepository implements RecordingPauseRepository {
  List<RecordingPause> pauses = [];

  @override
  Future<List<RecordingPause>> getPauses(DateTime from, DateTime to) async {
    return [
      for (final pause in pauses)
        if (pause.overlaps(from, to)) pause,
    ];
  }
}

class FakeRegisteredPlaceRepository implements RegisteredPlaceRepository {
  List<RegisteredPlace> places = [];

  @override
  Future<List<RegisteredPlace>> getAll() async => places;

  @override
  Future<void> save(RegisteredPlace place) async {
    places = [...places, place];
  }

  @override
  Future<void> delete(int id) async {
    places = [
      for (final place in places)
        if (place.id != id) place,
    ];
  }
}

void main() {
  late FakeLocationRepository locations;
  late FakePlaceNameRepository placeNames;
  late FakePlaceSearchRepository placeSearch;
  late FakeTimelineEditRepository edits;
  late FakeTimelineSnapshotRepository snapshots;
  late FakeRecordingPauseRepository recordingPauses;
  late FakeRegisteredPlaceRepository registeredPlaces;
  late GetTimelineByDateUseCase useCase;

  setUp(() {
    locations = FakeLocationRepository();
    placeNames = FakePlaceNameRepository();
    placeSearch = FakePlaceSearchRepository();
    edits = FakeTimelineEditRepository();
    snapshots = FakeTimelineSnapshotRepository();
    recordingPauses = FakeRecordingPauseRepository();
    registeredPlaces = FakeRegisteredPlaceRepository();

    useCase = GetTimelineByDateUseCase(
      repository: locations,
      placeNameRepository: placeNames,
      timelineEditRepository: edits,
      placeSearchRepository: placeSearch,
      activityRepository: FakeActivityRepository(),
      timelineSnapshotRepository: snapshots,
      recordingPauseRepository: recordingPauses,
      registeredPlaceRepository: registeredPlaces,
    );
  });

  group('登録した場所', () {
    test('登録した場所を訪れたときは、地名も施設も問い合わせずに登録した名前を表示する', () async {
      registeredPlaces.places = [
        const RegisteredPlace(
          id: 1,
          latitude: 35.0,
          longitude: 139.0,
          name: '行きつけの店',
        ),
      ];

      final stay = (await useCase.execute(day)).single as Stay;

      expect(stay.displayName, '行きつけの店');
      expect(stay.isPlaceNameEdited, isTrue);
      expect(placeNames.callCount, 0);
      expect(placeSearch.callCount, 0);
    });

    test('登録した場所は、施設を検索できなくても取得できた扱いにして保存する', () async {
      registeredPlaces.places = [
        const RegisteredPlace(
          id: 1,
          latitude: 35.0,
          longitude: 139.0,
          name: '行きつけの店',
        ),
      ];
      placeSearch.shouldFail = true;

      await useCase.execute(day);

      expect(snapshots.saved, isNotNull);
    });

    test('離れた場所には当てはめず、これまで通り取得する', () async {
      registeredPlaces.places = [
        const RegisteredPlace(
          id: 1,
          latitude: 35.01,
          longitude: 139.0,
          name: '行きつけの店',
        ),
      ];

      final stay = (await useCase.execute(day)).single as Stay;

      expect(stay.displayName, 'カフェA');
      expect(placeNames.callCount, 1);
    });

    test('その滞在に対する修正は、登録した名前より優先する', () async {
      registeredPlaces.places = [
        const RegisteredPlace(
          id: 1,
          latitude: 35.0,
          longitude: 139.0,
          name: '行きつけの店',
        ),
      ];
      edits.edits = [
        TimelineEdit(
          type: TimelineEditType.stay,
          start: DateTime(2026, 1, 1, 9, 0),
          end: DateTime(2026, 1, 1, 11, 0),
          placeName: '友人の家',
        ),
      ];

      final stay = (await useCase.execute(day)).single as Stay;

      expect(stay.displayName, '友人の家');
    });

    test('保存後に登録した場所が変わった場合は計算し直す', () async {
      await useCase.execute(day);

      registeredPlaces.places = [
        const RegisteredPlace(
          id: 1,
          latitude: 35.0,
          longitude: 139.0,
          name: '行きつけの店',
        ),
      ];

      final stay = (await useCase.execute(day)).single as Stay;

      expect(stay.displayName, '行きつけの店');

      // 登録を取り消すと、取得した場所名に戻る
      registeredPlaces.places = [];

      final reverted = (await useCase.execute(day)).single as Stay;

      expect(reverted.displayName, 'カフェA');
      expect(reverted.placeName, '東京都千代田区');
    });
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
    expect((items.single as Stay).isPlaceSearchFailed, isTrue);
  });

  test('施設を検索できなかった場所があれば保存せず、次回もう一度検索する', () async {
    placeSearch.failingIndexes = {0};

    final failed = await useCase.execute(day);

    expect(snapshots.saved, isNull);
    expect((failed.single as Stay).displayName, '東京都千代田区');
    expect((failed.single as Stay).isPlaceSearchFailed, isTrue);

    placeSearch.failingIndexes = {};

    final retried = await useCase.execute(day);

    expect(placeSearch.callCount, 2);
    expect((retried.single as Stay).displayName, 'カフェA');
    expect((retried.single as Stay).isPlaceSearchFailed, isFalse);
    expect(snapshots.saved, isNotNull);
  });

  test('複数の滞在の地名は、並行して取得し、滞在ごとに当てはめる', () async {
    final slow = SlowPlaceNameRepository();

    useCase = GetTimelineByDateUseCase(
      repository: locations,
      placeNameRepository: slow,
      timelineEditRepository: edits,
      placeSearchRepository: placeSearch,
      activityRepository: FakeActivityRepository(),
      timelineSnapshotRepository: snapshots,
      recordingPauseRepository: recordingPauses,
      registeredPlaceRepository: registeredPlaces,
    );

    locations.locations = [
      point(9, 0, 35.0),
      point(10, 0, 35.0001),
      point(11, 0, 36.0),
      point(12, 0, 36.0001),
      point(13, 0, 37.0),
      point(14, 0, 37.0001),
    ];

    final items = await useCase.execute(day, estimatePlaces: false);
    final stays = items.whereType<Stay>().toList();

    expect(stays.length, greaterThan(1));
    expect(slow.maxRunning, greaterThan(1));
    expect(slow.maxRunning, lessThanOrEqualTo(4));

    for (final stay in stays) {
      expect(stay.placeName, '地名${stay.latitude}');
    }
  });

  test('地名の取得が終わらない場合も、待ちきれずに先に進み、保存しない', () async {
    useCase = GetTimelineByDateUseCase(
      repository: locations,
      placeNameRepository: HangingPlaceNameRepository(),
      timelineEditRepository: edits,
      placeSearchRepository: placeSearch,
      activityRepository: FakeActivityRepository(),
      timelineSnapshotRepository: snapshots,
      recordingPauseRepository: recordingPauses,
      registeredPlaceRepository: registeredPlaces,
      placeNameTimeout: const Duration(milliseconds: 50),
    );

    final items = await useCase.execute(day);

    expect(items.whereType<Stay>(), isNotEmpty);
    expect((items.whereType<Stay>().first).placeName, isNull);
    expect(snapshots.saved, isNull);
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

  group('記録をオフにしていた期間', () {
    test('オフにした時刻で滞在を区切り、オフの間は何もなかったものとして扱う', () async {
      // 9:00〜10:00は同じ場所、10:00〜14:00はオフ、14:00〜15:00は同じ場所
      locations.locations = [
        point(9, 0, 35.0),
        point(9, 30, 35.0001),
        point(14, 0, 35.0),
        point(15, 0, 35.0001),
      ];
      recordingPauses.pauses = [
        RecordingPause(
          start: DateTime(2026, 1, 1, 10, 0),
          end: DateTime(2026, 1, 1, 14, 0),
        ),
      ];

      final items = await useCase.execute(day);

      expect(items, hasLength(3));
      // オフにした時刻までは、最後にいた場所にとどまっていたものとして扱う
      expect(items[0], isA<Stay>());
      expect(items[0].start, DateTime(2026, 1, 1, 9, 0));
      expect(items[0].end, DateTime(2026, 1, 1, 10, 0));
      // オフにしていた時間帯は、その間に表示する
      expect(items[1], isA<RecordingOff>());
      expect(items[1].start, DateTime(2026, 1, 1, 10, 0));
      expect(items[1].end, DateTime(2026, 1, 1, 14, 0));
      expect(items[2], isA<Stay>());
      expect(items[2].start, DateTime(2026, 1, 1, 14, 0));
      expect(items[2].end, DateTime(2026, 1, 1, 15, 0));
    });

    test('オフにしていた時間帯は、その日に重なる部分だけを表示する', () async {
      locations.locations = [];
      recordingPauses.pauses = [
        RecordingPause(
          start: DateTime(2025, 12, 31, 20, 0),
          end: DateTime(2026, 1, 1, 8, 0),
        ),
        RecordingPause(start: DateTime(2026, 1, 1, 22, 0)),
      ];

      final items = await useCase.execute(day);

      expect(items, hasLength(2));
      expect(items.every((e) => e is RecordingOff), isTrue);
      expect(items[0].start, DateTime(2026, 1, 1, 0, 0));
      expect(items[0].end, DateTime(2026, 1, 1, 8, 0));
      expect(items[1].start, DateTime(2026, 1, 1, 22, 0));
      expect(items[1].end, DateTime(2026, 1, 1, 23, 59, 59));
    });

    test('すぐオンに戻した場合は、滞在を区切らない', () async {
      locations.locations = [
        point(9, 0, 35.0),
        point(10, 1, 35.0001),
        point(11, 0, 35.0),
      ];
      recordingPauses.pauses = [
        RecordingPause(
          start: DateTime(2026, 1, 1, 10, 0),
          end: DateTime(2026, 1, 1, 10, 1),
        ),
      ];

      final stay = (await useCase.execute(day)).single as Stay;

      expect(stay.start, DateTime(2026, 1, 1, 9, 0));
      expect(stay.end, DateTime(2026, 1, 1, 11, 0));
    });

    test('前の日との間でオフにしていた場合は、日をまたいだ滞在にしない', () async {
      locations.previous = Location(
        id: 0,
        latitude: 35.0,
        longitude: 139.0,
        timestamp: DateTime(2025, 12, 31, 22, 0),
      );
      recordingPauses.pauses = [
        RecordingPause(
          start: DateTime(2025, 12, 31, 23, 0),
          end: DateTime(2026, 1, 1, 8, 0),
        ),
      ];

      final stay = (await useCase.execute(day)).whereType<Stay>().single;

      expect(stay.start, DateTime(2026, 1, 1, 9, 0));
    });

    test('翌日との間でオフにしていた場合は、その日の終わりまでの滞在にしない', () async {
      locations.next = Location(
        id: 0,
        latitude: 35.0001,
        longitude: 139.0,
        timestamp: DateTime(2026, 1, 2, 8, 0),
      );
      recordingPauses.pauses = [
        RecordingPause(
          start: DateTime(2026, 1, 1, 12, 0),
          end: DateTime(2026, 1, 2, 7, 0),
        ),
      ];

      final stay = (await useCase.execute(day)).whereType<Stay>().single;

      expect(stay.end, DateTime(2026, 1, 1, 12, 0));
    });

    test('今もオフのままの場合は、今の時刻までの滞在にしない', () async {
      final now = DateTime.now();
      final lastPoint = now.subtract(const Duration(hours: 2));
      final pausedAt = now.subtract(const Duration(hours: 1));

      locations.locations = [
        Location(
          id: 0,
          latitude: 35.0,
          longitude: 139.0,
          timestamp: lastPoint,
        ),
      ];
      recordingPauses.pauses = [RecordingPause(start: pausedAt)];

      final items = await useCase.execute(now);

      // 日付が変わった直後は、記録がその日に入らないため確認しない
      if (lastPoint.day != now.day) return;

      expect(items.whereType<Stay>().single.end, pausedAt);
      expect(items.last, isA<RecordingOff>());
      expect(items.last.start, pausedAt);
    });

    test('保存後にオフにしていた期間が変わった場合は計算し直す', () async {
      await useCase.execute(day);

      recordingPauses.pauses = [
        RecordingPause(
          start: DateTime(2026, 1, 1, 10, 0),
          end: DateTime(2026, 1, 1, 10, 30),
        ),
      ];
      await useCase.execute(day);

      expect(placeNames.callCount, 2);
    });
  });
}
