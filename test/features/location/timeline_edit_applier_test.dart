import 'package:auto_diary_ai/features/location/domain/entities/timeline_edit.dart';
import 'package:auto_diary_ai/features/location/domain/entities/timeline_item.dart';
import 'package:auto_diary_ai/features/location/domain/entities/transport_mode.dart';
import 'package:auto_diary_ai/features/location/domain/services/timeline_edit_applier.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final applier = TimelineEditApplier();

  DateTime at(int hour, int minute) => DateTime(2026, 1, 1, hour, minute);

  Stay stay(DateTime start, DateTime end) {
    return Stay(start: start, end: end, latitude: 35.0, longitude: 139.0);
  }

  Move move(DateTime start, DateTime end) {
    return Move(start: start, end: end, distanceMeters: 1000);
  }

  test('修正がなければそのまま返す', () {
    final items = applier.apply([stay(at(9, 0), at(10, 0))], []);

    final result = items.single as Stay;
    expect(result.placeName, isNull);
    expect(result.isPlaceNameEdited, isFalse);
  });

  test('滞在に場所名の修正を当てはめる', () {
    final items = applier.apply(
      [stay(at(9, 0), at(10, 0))],
      [
        TimelineEdit(
          type: TimelineEditType.stay,
          start: at(9, 0),
          end: at(10, 0),
          placeName: '自宅',
        ),
      ],
    );

    final result = items.single as Stay;
    expect(result.placeName, '自宅');
    expect(result.isPlaceNameEdited, isTrue);
  });

  test('移動に移動手段の修正を当てはめる', () {
    final items = applier.apply(
      [move(at(10, 0), at(10, 30))],
      [
        TimelineEdit(
          type: TimelineEditType.move,
          start: at(10, 0),
          end: at(10, 30),
          transport: TransportMode.train,
        ),
      ],
    );

    expect((items.single as Move).transport, TransportMode.train);
  });

  test('移動に自由に書いた説明を当てはめる', () {
    final items = applier.apply(
      [move(at(10, 0), at(10, 30))],
      [
        TimelineEdit(
          type: TimelineEditType.move,
          start: at(10, 0),
          end: at(10, 30),
          transport: TransportMode.car,
          transportText: '友人の車で移動',
        ),
      ],
    );

    final result = items.single as Move;
    expect(result.transport, TransportMode.car);
    expect(result.transportText, '友人の車で移動');
    expect(result.isTransportEdited, isTrue);
  });

  test('滞在の時刻が多少ずれても同じ滞在に当てはめる', () {
    final items = applier.apply(
      [stay(at(9, 5), at(10, 20))],
      [
        TimelineEdit(
          type: TimelineEditType.stay,
          start: at(9, 0),
          end: at(10, 0),
          placeName: '自宅',
        ),
      ],
    );

    expect((items.single as Stay).placeName, '自宅');
  });

  test('重なりが小さい場合は別の滞在とみなす', () {
    final items = applier.apply(
      [stay(at(9, 50), at(12, 0))],
      [
        TimelineEdit(
          type: TimelineEditType.stay,
          start: at(9, 0),
          end: at(10, 0),
          placeName: '自宅',
        ),
      ],
    );

    expect((items.single as Stay).placeName, isNull);
  });

  test('滞在の修正は移動には当てはめない', () {
    final items = applier.apply(
      [move(at(9, 0), at(10, 0))],
      [
        TimelineEdit(
          type: TimelineEditType.stay,
          start: at(9, 0),
          end: at(10, 0),
          placeName: '自宅',
        ),
      ],
    );

    expect((items.single as Move).transport, isNull);
  });

  test('複数の修正がある場合は重なりが最も大きいものを選ぶ', () {
    final edits = [
      TimelineEdit(
        type: TimelineEditType.stay,
        start: at(8, 0),
        end: at(9, 30),
        placeName: '自宅',
      ),
      TimelineEdit(
        type: TimelineEditType.stay,
        start: at(9, 30),
        end: at(12, 0),
        placeName: '会社',
      ),
    ];

    final matched = applier.match(stay(at(9, 0), at(12, 0)), edits);

    expect(matched?.placeName, '会社');
  });
}
