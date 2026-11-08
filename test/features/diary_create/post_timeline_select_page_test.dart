import 'package:auto_diary_ai/features/diary_create/presentation/ui/post_select_page.dart';
import 'package:auto_diary_ai/features/diary_create/presentation/ui/timeline_select_page.dart';
import 'package:auto_diary_ai/features/location/domain/entities/timeline_item.dart';
import 'package:auto_diary_ai/features/share/domain/entities/shared_post.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

SharedPost post(int id, int month, int day) => SharedPost(
  id: id,
  url: 'u$id',
  text: 'p$id',
  receivedAt: DateTime(2026, month, day, 9),
);

Stay stay(int month, int day) => Stay(
  start: DateTime(2026, month, day, 9),
  end: DateTime(2026, month, day, 10),
  latitude: 35,
  longitude: 139,
  placeName: '場所$month/$day',
);

void main() {
  final posts = [post(1, 1, 1), post(2, 1, 2), post(3, 2, 1)];
  final items = [stay(1, 1), stay(1, 2), stay(2, 1)];

  group('Xの投稿の選択画面', () {
    Future<void> open(WidgetTester tester) => tester.pumpWidget(
      MaterialApp(
        home: PostSelectPage(posts: posts, initialSelection: const []),
      ),
    );

    testWidgets('月は初めは閉じていて、月ごとにまとめて選択・解除できる', (tester) async {
      await open(tester);

      expect(find.text('2026年1月  0/2'), findsOneWidget);
      expect(find.text('p1'), findsNothing);

      await tester.tap(find.text('この月をすべて選択').first);
      await tester.pump();

      expect(find.text('2026年1月  2/2'), findsOneWidget);
      expect(find.text('Xの投稿 (2/3)'), findsOneWidget);

      await tester.tap(find.text('この月を解除'));
      await tester.pump();

      expect(find.text('Xの投稿 (0/3)'), findsOneWidget);
    });

    testWidgets('見出しを押すと、その月の投稿が開く', (tester) async {
      await open(tester);

      await tester.tap(find.text('2026年1月  0/2'));
      await tester.pump();

      expect(find.text('p1'), findsOneWidget);
      expect(find.text('p3'), findsNothing);
    });
  });

  group('行動履歴の選択画面', () {
    Future<void> open(WidgetTester tester) => tester.pumpWidget(
      MaterialApp(
        home: TimelineSelectPage(items: items, initialSelection: const []),
      ),
    );

    testWidgets('月は初めは閉じていて、月ごとにまとめて選択・解除できる', (tester) async {
      await open(tester);

      expect(find.text('2026年1月  0/2'), findsOneWidget);
      expect(find.text('2026年2月  0/1'), findsOneWidget);

      await tester.tap(find.text('この月をすべて選択').last);
      await tester.pump();

      expect(find.text('2026年2月  1/1'), findsOneWidget);
      expect(find.text('行動履歴 (1/3)'), findsOneWidget);

      await tester.tap(find.text('この月を解除'));
      await tester.pump();

      expect(find.text('行動履歴 (0/3)'), findsOneWidget);
    });

    testWidgets('見出しを押すと、その月の行動履歴が開く', (tester) async {
      await open(tester);

      await tester.tap(find.text('2026年2月  0/1'));
      await tester.pump();

      expect(find.text('場所2/1'), findsOneWidget);
      expect(find.text('場所1/1'), findsNothing);
    });
  });
}
