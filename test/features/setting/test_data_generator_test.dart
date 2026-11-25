import 'dart:math' as math;
import 'package:auto_diary_ai/features/location/domain/entities/location.dart';
import 'package:auto_diary_ai/features/location/domain/entities/registered_place.dart';
import 'package:auto_diary_ai/features/location/domain/entities/timeline_item.dart';
import 'package:auto_diary_ai/features/location/domain/services/registered_place_finder.dart';
import 'package:auto_diary_ai/features/location/domain/services/timeline_builder.dart';
import 'package:auto_diary_ai/features/setting/domain/services/test_location_generator.dart';
import 'package:auto_diary_ai/features/setting/domain/services/test_post_generator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final first = DateTime(2026, 1, 1);
  final last = DateTime(2026, 10, 27);

  group('テスト用のXの投稿', () {
    final posts = TestPostGenerator.generate(first: first, last: last);

    test('日記と同じ期間に、全部で300件以上できる', () {
      expect(posts.length, inInclusiveRange(300, 600));
      expect(
        posts.every(
          (e) =>
              !e.receivedAt.isBefore(first) &&
              e.receivedAt.isBefore(DateTime(2026, 10, 28)),
        ),
        isTrue,
      );
    });

    test('URLはすべて違い、テスト用の目印で始まる。本文は140文字以内', () {
      expect(posts.map((e) => e.url).toSet().length, posts.length);
      expect(posts.every(TestPostGenerator.isTestPost), isTrue);
      expect(
        posts.every((e) => e.text.isNotEmpty && e.text.length <= 140),
        isTrue,
      );
    });

    test('同じ日に、同じ本文は入らない', () {
      final byDay = <String, Set<String>>{};

      for (final post in posts) {
        final key = "${post.receivedAt.month}/${post.receivedAt.day}";
        expect(
          byDay.putIfAbsent(key, () => {}).add(post.text),
          isTrue,
          reason: key,
        );
      }
    });

    test('旅行や特別な日は、その日の出来事の投稿になる', () {
      String of(int month, int day) => [
        for (final p in posts)
          if (p.receivedAt.month == month && p.receivedAt.day == day) p.text,
      ].join();

      expect(of(1, 1), contains('初詣'));
      expect(of(5, 3), contains('京都'));
      expect(of(8, 10), contains('灯台'));
      expect(of(10, 11), contains('10キロ'));
    });

    test('同じ入力なら、いつも同じ投稿ができる', () {
      final again = TestPostGenerator.generate(first: first, last: last);

      expect(
        again.map((e) => e.text).toList(),
        posts.map((e) => e.text).toList(),
      );
      expect(
        again.map((e) => e.receivedAt).toList(),
        posts.map((e) => e.receivedAt).toList(),
      );
    });
  });

  group('テスト用の行動履歴', () {
    final data = TestLocationGenerator.generate(first: first, last: last);

    final registered = [
      for (final p in data.places)
        RegisteredPlace(
          latitude: p.latitude,
          longitude: p.longitude,
          name: p.name,
        ),
    ];

    double distanceKm(TestLocationPoint a, TestLocationPoint b) {
      const toRad = math.pi / 180;
      final dLat = (b.latitude - a.latitude) * toRad;
      final dLng = (b.longitude - a.longitude) * toRad;
      final h =
          math.sin(dLat / 2) * math.sin(dLat / 2) +
          math.cos(a.latitude * toRad) *
              math.cos(b.latitude * toRad) *
              math.sin(dLng / 2) *
              math.sin(dLng / 2);

      return 2 * 6371 * math.asin(math.min(1.0, math.sqrt(h)));
    }

    // その日の滞在を、登録した場所の名前にして返す
    List<String?> stayNames(DateTime day) {
      final locations = <Location>[
        for (final p in data.points)
          if (p.time.year == day.year &&
              p.time.month == day.month &&
              p.time.day == day.day)
            Location(
              id: 0,
              latitude: p.latitude,
              longitude: p.longitude,
              timestamp: p.time,
            ),
      ];

      final items = TimelineBuilder().build(
        locations,
        dayStart: day,
        dayEnd: DateTime(day.year, day.month, day.day + 1),
      );

      return [
        for (final stay in items.whereType<Stay>())
          RegisteredPlaceFinder().find(stay, registered)?.name,
      ];
    }

    test('少なめの件数(約60日分)で、旅行の日が入っている', () {
      expect(data.points.length, inInclusiveRange(1000, 4000));

      final days = {for (final p in data.points) "${p.time.month}/${p.time.day}"};

      expect(days.length, inInclusiveRange(50, 80));
      expect(
        days,
        containsAll(['5/3', '5/4', '5/5', '8/9', '8/10', '8/11', '1/1']),
      );
    });

    test('滞在する場所の名前は、テスト用の目印で始まる', () {
      expect(data.places, isNotEmpty);
      expect(
        data.places.every(
          (e) => e.name.startsWith(TestLocationGenerator.namePrefix),
        ),
        isTrue,
      );
      expect(data.places.map((e) => e.name).toSet().length, data.places.length);
    });

    test('時刻順に並べると、点の間の速さは、現実的(時速300km以下)', () {
      final sorted = [...data.points]
        ..sort((a, b) => a.time.compareTo(b.time));

      for (var i = 1; i < sorted.length; i++) {
        final hours =
            sorted[i].time.difference(sorted[i - 1].time).inSeconds / 3600;
        if (hours <= 0) continue;

        expect(
          distanceKm(sorted[i - 1], sorted[i]) / hours,
          lessThan(300),
          reason: '${sorted[i].time}',
        );
      }
    });

    test('平日は、自宅・職場・自宅の滞在になり、登録した場所の名前に結び付く', () {
      // 2026年1月6日(火)
      final names = stayNames(DateTime(2026, 1, 6));

      expect(names.length, greaterThanOrEqualTo(3));
      expect(names, everyElement(isNotNull));
      expect(names.first, '【テスト】自宅');
      expect(names, contains('【テスト】職場'));
    });

    test('京都の旅行の日は、京都の場所に滞在する', () {
      final names = stayNames(DateTime(2026, 5, 4));

      expect(
        names,
        containsAll([
          '【テスト】清水寺',
          '【テスト】錦市場',
          '【テスト】嵐山の竹林',
          '【テスト】京都の宿',
        ]),
      );
    });

    test('海辺の旅行の日は、海辺の場所に滞在する', () {
      final names = stayNames(DateTime(2026, 8, 10));

      expect(
        names,
        containsAll(['【テスト】漁港の市場', '【テスト】岬の灯台', '【テスト】海辺の町の宿']),
      );
    });
  });
}
