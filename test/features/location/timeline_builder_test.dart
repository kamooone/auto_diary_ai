import 'package:auto_diary_ai/features/location/domain/entities/location.dart';
import 'package:auto_diary_ai/features/location/domain/entities/timeline_item.dart';
import 'package:auto_diary_ai/features/location/domain/services/timeline_builder.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final builder = TimelineBuilder();

  // 緯度0.001度は約111m
  Location point(int hour, int minute, double latitude) {
    return Location(
      id: 0,
      latitude: latitude,
      longitude: 139.0,
      timestamp: DateTime(2026, 1, 1, hour, minute),
    );
  }

  test('位置情報がなければ空になる', () {
    expect(builder.build([]), isEmpty);
  });

  test('同じ場所に5分以上いると滞在になる', () {
    final items = builder.build([
      point(9, 0, 35.0),
      point(11, 0, 35.0001),
    ]);

    expect(items, hasLength(1));
    final stay = items.single as Stay;
    expect(stay.start, DateTime(2026, 1, 1, 9, 0));
    expect(stay.end, DateTime(2026, 1, 1, 11, 0));
  });

  test('滞在と滞在の間は移動になる', () {
    final items = builder.build([
      point(9, 0, 35.0),
      point(10, 0, 35.0001),
      point(10, 5, 35.005),
      point(10, 10, 35.01),
      point(12, 0, 35.0101),
    ]);

    expect(items.map((e) => e.runtimeType), [Stay, Move, Stay]);

    final move = items[1] as Move;
    expect(move.start, DateTime(2026, 1, 1, 10, 0));
    expect(move.end, DateTime(2026, 1, 1, 10, 10));
    expect(move.distanceMeters, closeTo(1100, 30));
  });

  test('記録が途切れていても、滞在の間は直線距離の移動になる', () {
    final items = builder.build([
      point(9, 0, 35.0),
      point(10, 0, 35.0001),
      point(11, 0, 35.02),
      point(12, 0, 35.0201),
    ]);

    expect(items.map((e) => e.runtimeType), [Stay, Move, Stay]);
    expect((items[1] as Move).distanceMeters, closeTo(2210, 30));
  });

  test('時刻順でなくても正しく並べる', () {
    final items = builder.build([
      point(11, 0, 35.0001),
      point(9, 0, 35.0),
    ]);

    expect((items.single as Stay).start, DateTime(2026, 1, 1, 9, 0));
  });

  test('untilを渡すと最後の場所にとどまっているものとして扱う', () {
    final locations = [
      point(9, 0, 35.0),
      point(10, 0, 35.0001),
      point(10, 10, 35.01),
    ];

    expect(builder.build(locations).last, isA<Move>());

    final items = builder.build(
      locations,
      until: DateTime(2026, 1, 1, 13, 0),
    );
    final last = items.last as Stay;
    expect(last.start, DateTime(2026, 1, 1, 10, 10));
    expect(last.end, DateTime(2026, 1, 1, 13, 0));
  });
}
