import 'package:auto_diary_ai/features/location/domain/entities/registered_place.dart';
import 'package:auto_diary_ai/features/location/domain/entities/timeline_edit.dart';
import 'package:auto_diary_ai/features/location/domain/entities/timeline_item.dart';
import 'package:auto_diary_ai/features/location/domain/repositories/registered_place_repository.dart';
import 'package:auto_diary_ai/features/location/domain/repositories/timeline_edit_repository.dart';
import 'package:auto_diary_ai/features/location/domain/usecases/update_stay_place_name_usecase.dart';
import 'package:flutter_test/flutter_test.dart';

class InMemoryTimelineEditRepository implements TimelineEditRepository {
  final edits = <TimelineEdit>[];
  var _nextId = 1;

  @override
  Future<List<TimelineEdit>> findOverlapping(
    DateTime start,
    DateTime end,
  ) async {
    return [
      for (final edit in edits)
        if (edit.start.isBefore(end) && edit.end.isAfter(start)) edit,
    ];
  }

  @override
  Future<void> save(TimelineEdit edit) async {
    edits.removeWhere((e) => e.id != null && e.id == edit.id);
    edits.add(
      TimelineEdit(
        id: edit.id ?? _nextId++,
        type: edit.type,
        start: edit.start,
        end: edit.end,
        placeName: edit.placeName,
      ),
    );
  }

  @override
  Future<void> delete(int id) async {
    edits.removeWhere((e) => e.id == id);
  }
}

class InMemoryRegisteredPlaceRepository implements RegisteredPlaceRepository {
  final places = <RegisteredPlace>[];
  var _nextId = 1;

  @override
  Future<List<RegisteredPlace>> getAll() async => List.of(places);

  @override
  Future<void> save(RegisteredPlace place) async {
    places.removeWhere((e) => e.id != null && e.id == place.id);
    places.add(
      RegisteredPlace(
        id: place.id ?? _nextId++,
        latitude: place.latitude,
        longitude: place.longitude,
        name: place.name,
      ),
    );
  }

  @override
  Future<void> delete(int id) async {
    places.removeWhere((e) => e.id == id);
  }
}

Stay stayAt(double latitude, {int hour = 9}) {
  return Stay(
    start: DateTime(2026, 1, 1, hour, 0),
    end: DateTime(2026, 1, 1, hour + 1, 0),
    latitude: latitude,
    longitude: 139.0,
  );
}

void main() {
  late InMemoryTimelineEditRepository edits;
  late InMemoryRegisteredPlaceRepository registeredPlaces;
  late UpdateStayPlaceNameUseCase useCase;

  setUp(() {
    edits = InMemoryTimelineEditRepository();
    registeredPlaces = InMemoryRegisteredPlaceRepository();
    useCase = UpdateStayPlaceNameUseCase(edits, registeredPlaces);
  });

  test('場所名を入力すると、その場所を登録する', () async {
    await useCase.execute(stayAt(35.0), ' 行きつけの店 ', registerPlace: true);

    expect(edits.edits.single.placeName, '行きつけの店');
    expect(registeredPlaces.places.single.name, '行きつけの店');
    expect(registeredPlaces.places.single.latitude, 35.0);
  });

  test('訪れた場所を取得できていた滞在も、登録すると選べば登録する', () async {
    final stay = Stay(
      start: DateTime(2026, 1, 1, 9, 0),
      end: DateTime(2026, 1, 1, 10, 0),
      latitude: 35.0,
      longitude: 139.0,
      estimatedPlaceName: '東京駅',
    );

    await useCase.execute(stay, '東京駅バス停', registerPlace: true);

    expect(edits.edits.single.placeName, '東京駅バス停');
    expect(registeredPlaces.places.single.name, '東京駅バス停');
  });

  test('訪れた場所を取得できていた滞在も、登録しないと選べばその滞在だけの修正にする', () async {
    final stay = Stay(
      start: DateTime(2026, 1, 1, 9, 0),
      end: DateTime(2026, 1, 1, 10, 0),
      latitude: 35.0,
      longitude: 139.0,
      estimatedPlaceName: '東京駅',
    );

    await useCase.execute(stay, '東京駅バス停');

    expect(edits.edits.single.placeName, '東京駅バス停');
    expect(registeredPlaces.places, isEmpty);
  });

  test('施設を検索できなかった滞在も、登録すると選べば登録する', () async {
    final stay = Stay(
      start: DateTime(2026, 1, 1, 9, 0),
      end: DateTime(2026, 1, 1, 10, 0),
      latitude: 35.0,
      longitude: 139.0,
      isPlaceSearchFailed: true,
    );

    await useCase.execute(stay, '自宅', registerPlace: true);

    expect(edits.edits.single.placeName, '自宅');
    expect(registeredPlaces.places.single.name, '自宅');
  });

  test('登録しないと選んだ場合は、その滞在だけの修正にする', () async {
    await useCase.execute(stayAt(35.0), '行きつけの店');

    expect(edits.edits.single.placeName, '行きつけの店');
    expect(registeredPlaces.places, isEmpty);
  });

  test('登録した場所の近くで入力し直して登録すると、登録を新しく増やさず名前を更新する', () async {
    await useCase.execute(stayAt(35.0), '行きつけの店', registerPlace: true);
    await useCase.execute(
      stayAt(35.0001, hour: 15),
      '新しい店名',
      registerPlace: true,
    );

    expect(registeredPlaces.places, hasLength(1));
    expect(registeredPlaces.places.single.name, '新しい店名');
  });

  test('登録した場所の近くで入力し直して登録しない場合は、登録した名前を変えない', () async {
    await useCase.execute(stayAt(35.0), '行きつけの店', registerPlace: true);
    await useCase.execute(stayAt(35.0001, hour: 15), 'この日だけの名前');

    expect(registeredPlaces.places.single.name, '行きつけの店');
    expect(edits.edits.map((e) => e.placeName), contains('この日だけの名前'));
  });

  test('離れた場所で入力すると、別の場所として登録する', () async {
    await useCase.execute(stayAt(35.0), '行きつけの店', registerPlace: true);
    await useCase.execute(
      stayAt(35.01, hour: 15),
      '別の店',
      registerPlace: true,
    );

    expect(registeredPlaces.places, hasLength(2));
  });

  test('場所名を空にすると、修正と登録を取り消す', () async {
    await useCase.execute(stayAt(35.0), '行きつけの店', registerPlace: true);
    await useCase.execute(stayAt(35.0), null);

    expect(edits.edits, isEmpty);
    expect(registeredPlaces.places, isEmpty);
  });

  test('登録した場所を訪れた別の日の滞在から取り消すこともできる', () async {
    await useCase.execute(stayAt(35.0), '行きつけの店', registerPlace: true);

    // 別の日の滞在(この日には修正がない)
    final another = Stay(
      start: DateTime(2026, 1, 5, 9, 0),
      end: DateTime(2026, 1, 5, 10, 0),
      latitude: 35.0,
      longitude: 139.0,
      placeName: '行きつけの店',
      isPlaceNameEdited: true,
    );

    await useCase.execute(another, null);

    expect(registeredPlaces.places, isEmpty);
    expect(edits.edits, hasLength(1));
  });
}
