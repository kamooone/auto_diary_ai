import 'dart:typed_data';
import 'package:auto_diary_ai/features/diary_create/application/providers/diary_usecase_providers.dart';
import 'package:auto_diary_ai/features/diary_create/domain/entities/photo.dart';
import 'package:auto_diary_ai/features/diary_create/domain/repositories/photo_repository.dart';
import 'package:auto_diary_ai/features/diary_create/domain/services/photo_period_filter.dart';
import 'package:auto_diary_ai/features/diary_create/presentation/ui/photo_picker_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class FakePhotoRepository implements PhotoRepository {
  FakePhotoRepository(this.all);

  final List<Photo> all;

  /// 読み込みのたびに渡された期間
  final requests = <(DateTime?, DateTime?)>[];

  @override
  Future<List<Photo>> getPhotos({
    required int page,
    required int size,
    DateTime? from,
    DateTime? to,
  }) async {
    if (page == 0) requests.add((from, to));

    final matched = [
      for (final p in all)
        if ((from == null || !p.createdAt.isBefore(from)) &&
            (to == null || p.createdAt.isBefore(to)))
          p,
    ]..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return matched.skip(page * size).take(size).toList();
  }

  @override
  Future<DateTime?> getOldestDate() async => all.isEmpty
      ? null
      : all.map((e) => e.createdAt).reduce((a, b) => a.isBefore(b) ? a : b);

  @override
  Future<Uint8List?> getThumbnail(Photo photo) async => null;

  @override
  Future<Uint8List?> getJpeg(
    Photo photo, {
    required int maxSide,
    required int quality,
  }) async => null;
}

Photo photo(String id, DateTime at) => Photo(id: id, createdAt: at);

void main() {
  group('PhotoPeriodFilter', () {
    test('期間が1か月に収まるときは、その月から始める', () {
      final filter = PhotoPeriodFilter.initial(
        from: DateTime(2026, 11, 9),
        to: DateTime(2026, 11, 10),
      );

      expect((filter.year, filter.month), (2026, 11));
      expect(filter.from, DateTime(2026, 11, 1));
      expect(filter.to, DateTime(2026, 12, 1));
    });

    test('期間が複数の月にまたがるときは、始まりの年から始める', () {
      final filter = PhotoPeriodFilter.initial(
        from: DateTime(2026, 1, 1),
        to: DateTime(2026, 11, 9),
      );

      expect((filter.year, filter.month), (2026, null));
      expect(filter.from, DateTime(2026, 1, 1));
      expect(filter.to, DateTime(2027, 1, 1));
    });

    test('月をまたぐ期間(月末〜月初)も、年から始める', () {
      final filter = PhotoPeriodFilter.initial(
        from: DateTime(2026, 10, 31),
        to: DateTime(2026, 11, 2),
      );

      expect((filter.year, filter.month), (2026, null));
    });

    test('期間を渡さないときは、すべての写真(期間の制限なし)', () {
      final filter = PhotoPeriodFilter.initial();

      expect(filter, PhotoPeriodFilter.all);
      expect(filter.from, isNull);
      expect(filter.to, isNull);
    });

    test('12月は、翌年の1月までの範囲になる', () {
      const filter = PhotoPeriodFilter(year: 2026, month: 12);

      expect(filter.from, DateTime(2026, 12, 1));
      expect(filter.to, DateTime(2027, 1, 1));
    });

    test('年を変えると月は解除する', () {
      const filter = PhotoPeriodFilter(year: 2026, month: 5);

      expect(filter.withYear(2025).month, isNull);
      expect(filter.withMonth(6).year, 2026);
    });

    test('年の選択肢は、一番古い写真の年から今年まで(新しい年が先頭)', () {
      expect(
        PhotoPeriodFilter.years(
          oldest: DateTime(2024, 3, 1),
          now: DateTime(2026, 11, 9),
        ),
        [2026, 2025, 2024],
      );
      // 写真がないときは、今年だけ
      expect(
        PhotoPeriodFilter.years(oldest: null, now: DateTime(2026, 11, 9)),
        [2026],
      );
    });
  });

  group('写真を選ぶ画面', () {
    late FakePhotoRepository repository;

    setUp(() {
      repository = FakePhotoRepository([
        photo('nov', DateTime(2026, 11, 9, 10)),
        photo('oct', DateTime(2026, 10, 3, 10)),
        photo('old', DateTime(2025, 6, 1, 10)),
      ]);
    });

    Future<void> open(
      WidgetTester tester, {
      DateTime? from,
      DateTime? to,
    }) {
      return tester.pumpWidget(
        ProviderScope(
          overrides: [photoRepositoryProvider.overrideWithValue(repository)],
          child: MaterialApp(
            home: PhotoPickerPage(
              initialSelection: const [],
              from: from,
              to: to,
            ),
          ),
        ),
      );
    }

    int tileCount(WidgetTester tester) =>
        tester.widgetList(find.byType(GridView)).isEmpty
        ? 0
        : tester.widget<GridView>(find.byType(GridView)).semanticChildCount ?? 0;

    testWidgets('日記の日付の月から始まり、その月の写真だけ読み込む', (tester) async {
      await open(
        tester,
        from: DateTime(2026, 11, 9),
        to: DateTime(2026, 11, 10),
      );
      await tester.pumpAndSettle();

      expect(repository.requests.first, (
        DateTime(2026, 11, 1),
        DateTime(2026, 12, 1),
      ));
      expect(tileCount(tester), 1);
    });

    testWidgets('「すべて」にすると、すべての写真を読み込み直す', (tester) async {
      await open(
        tester,
        from: DateTime(2026, 11, 9),
        to: DateTime(2026, 11, 10),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('photoYear')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('すべて').last);
      await tester.pumpAndSettle();

      expect(repository.requests.last, (null, null));
      expect(tileCount(tester), 3);
    });

    testWidgets('ほかの年を選ぶと、その年の写真になる', (tester) async {
      await open(
        tester,
        from: DateTime(2026, 11, 9),
        to: DateTime(2026, 11, 10),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('photoYear')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('2025年').last);
      await tester.pumpAndSettle();

      expect(repository.requests.last, (
        DateTime(2025, 1, 1),
        DateTime(2026, 1, 1),
      ));
      expect(tileCount(tester), 1);
    });

    testWidgets('期間を渡さないときは、初めからすべての写真', (tester) async {
      await open(tester);
      await tester.pumpAndSettle();

      expect(repository.requests.first, (null, null));
      expect(tileCount(tester), 3);
    });

    testWidgets('年と月を変えても、選んだ写真は残る', (tester) async {
      await open(
        tester,
        from: DateTime(2026, 11, 9),
        to: DateTime(2026, 11, 10),
      );
      await tester.pumpAndSettle();

      // 11月の写真を選ぶ(写真のマスは、GridViewの中にある)
      await tester.tap(
        find.descendant(
          of: find.byType(GridView),
          matching: find.byType(GestureDetector),
        ),
      );
      await tester.pump();
      expect(find.text('写真を選択 (1枚)'), findsOneWidget);

      await tester.tap(find.byKey(const Key('photoYear')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('2025年').last);
      await tester.pumpAndSettle();

      expect(find.text('写真を選択 (1枚)'), findsOneWidget);
    });
  });
}
