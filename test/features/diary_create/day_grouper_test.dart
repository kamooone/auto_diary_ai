import 'package:auto_diary_ai/features/diary_create/domain/services/day_grouper.dart';
import 'package:auto_diary_ai/features/diary_create/presentation/ui/widgets/day_header.dart';
import 'package:auto_diary_ai/features/location/domain/entities/timeline_item.dart';
import 'package:auto_diary_ai/features/share/domain/entities/shared_post.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Stay stay(DateTime start, {DateTime? end}) {
  return Stay(
    start: start,
    end: end ?? start.add(const Duration(hours: 1)),
    latitude: 35.0,
    longitude: 139.0,
  );
}

SharedPost post(DateTime receivedAt) {
  return SharedPost(url: 'https://x.com/a', text: 'text', receivedAt: receivedAt);
}

void main() {
  group('groupByDay', () {
    test('行動履歴を日付ごとに分け、日付の古い順に並べる', () {
      final a = stay(DateTime(2026, 1, 3, 9));
      final b = stay(DateTime(2026, 1, 1, 10));
      final c = stay(DateTime(2026, 1, 3, 15));
      final d = stay(DateTime(2026, 1, 2, 8));

      final days = groupByDay<TimelineItem>([a, b, c, d], (e) => e.start);

      expect(days.map((e) => e.date), [
        DateTime(2026, 1, 1),
        DateTime(2026, 1, 2),
        DateTime(2026, 1, 3),
      ]);
      // 同じ日の中は、渡された順のまま
      expect(days.last.items, [a, c]);
    });

    test('日付をまたいだ滞在は、開始した日にまとめる', () {
      final night = stay(
        DateTime(2026, 1, 1, 22),
        end: DateTime(2026, 1, 2, 6),
      );

      final days = groupByDay<TimelineItem>([night], (e) => e.start);

      expect(days.single.date, DateTime(2026, 1, 1));
    });

    test('Xの投稿は、受け取った日ごとに分ける', () {
      final a = post(DateTime(2026, 1, 2, 23, 59));
      final b = post(DateTime(2026, 1, 3, 0, 1));

      final days = groupByDay<SharedPost>([a, b], (e) => e.receivedAt);

      expect(days, hasLength(2));
      expect(days.first.items, [a]);
      expect(days.last.items, [b]);
    });

    test('項目がなければ、空になる', () {
      expect(groupByDay<int>([], (_) => DateTime(2026)), isEmpty);
    });
  });

  group('DayHeader', () {
    test('日付を曜日つきで表示する', () {
      expect(DayHeader.dateText(DateTime(2026, 1, 1)), '2026年1月1日（木）');
      expect(DayHeader.dateText(DateTime(2026, 1, 4)), '2026年1月4日（日）');
    });

    Future<void> pump(
      WidgetTester tester, {
      required int selected,
      required int total,
      required VoidCallback onToggle,
    }) {
      return tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DayHeader(
              date: DateTime(2026, 1, 1),
              selectedCount: selected,
              totalCount: total,
              onToggle: onToggle,
            ),
          ),
        ),
      );
    }

    testWidgets('一部だけ選択しているときは「この日をすべて選択」を出す', (tester) async {
      var toggled = 0;
      await pump(tester, selected: 1, total: 3, onToggle: () => toggled++);

      expect(find.text('2026年1月1日（木）  1/3'), findsOneWidget);
      expect(find.text('この日をすべて選択'), findsOneWidget);

      await tester.tap(find.text('この日をすべて選択'));
      expect(toggled, 1);
    });

    testWidgets('その日がすべて選択されているときは「この日を解除」を出す', (tester) async {
      await pump(tester, selected: 3, total: 3, onToggle: () {});

      expect(find.text('この日を解除'), findsOneWidget);
    });
  });
}
