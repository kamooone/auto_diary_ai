import 'package:auto_diary_ai/features/diary/domain/entities/diary.dart';
import 'package:auto_diary_ai/features/diary_create/presentation/ui/diary_select_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Diary diary(int id, int month, int day) => Diary(
  id: id,
  date: DateTime(2026, month, day),
  title: 't$id',
  content: 'c$id',
  isAiGenerated: false,
  createdAt: DateTime(2026, month, day),
);

void main() {
  final diaries = [
    diary(1, 1, 1),
    diary(2, 1, 2),
    diary(3, 2, 1),
  ];

  testWidgets('月の見出しで、その月の日記をまとめて選択・解除できる', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: DiarySelectPage(diaries: diaries, initialSelection: const []),
      ),
    );

    expect(find.text('2026年1月  0/2'), findsOneWidget);
    expect(find.text('2026年2月  0/1'), findsOneWidget);

    await tester.tap(find.text('この月をすべて選択').first);
    await tester.pump();

    expect(find.text('2026年1月  2/2'), findsOneWidget);
    expect(find.text('2026年2月  0/1'), findsOneWidget);
    expect(find.text('日記 (2/3)'), findsOneWidget);

    await tester.tap(find.text('この月を解除'));
    await tester.pump();

    expect(find.text('2026年1月  0/2'), findsOneWidget);
  });

  testWidgets('日ごとの全選択は出さない', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: DiarySelectPage(diaries: diaries, initialSelection: const []),
      ),
    );

    // 月を開くと、日付が出る
    await tester.tap(find.text('2026年1月  0/2'));
    await tester.pump();

    expect(find.text('この日をすべて選択'), findsNothing);
    expect(find.text('2026年1月1日（木）'), findsOneWidget);
  });

  testWidgets('月は初めは閉じていて、見出しを押すと開閉する', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: DiarySelectPage(diaries: diaries, initialSelection: const []),
      ),
    );

    // 閉じている間は、月の見出しだけ
    expect(find.text('2026年1月  0/2'), findsOneWidget);
    expect(find.text('2026年2月  0/1'), findsOneWidget);
    expect(find.text('t1'), findsNothing);
    expect(find.text('t3'), findsNothing);
    expect(find.byIcon(Icons.chevron_right), findsNWidgets(2));

    await tester.tap(find.text('2026年1月  0/2'));
    await tester.pump();

    // 開いたのは1月だけ
    expect(find.text('t1'), findsOneWidget);
    expect(find.text('t2'), findsOneWidget);
    expect(find.text('t3'), findsNothing);
    expect(find.byIcon(Icons.expand_more), findsOneWidget);

    await tester.tap(find.text('2026年1月  0/2'));
    await tester.pump();

    expect(find.text('t1'), findsNothing);
  });

  testWidgets('閉じていても、月ごとの選択と、選んだ件数は使える', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: DiarySelectPage(diaries: diaries, initialSelection: const []),
      ),
    );

    await tester.tap(find.text('この月をすべて選択').first);
    await tester.pump();

    expect(find.text('2026年1月  2/2'), findsOneWidget);
    expect(find.text('日記 (2/3)'), findsOneWidget);
    expect(find.text('t1'), findsNothing);

    // 閉じたままでも、選んだ日記は残る
    await tester.tap(find.text('2026年1月  2/2'));
    await tester.pump();

    expect(find.text('t1'), findsOneWidget);
    expect(
      tester.widget<CheckboxListTile>(find.widgetWithText(CheckboxListTile, 't1')).value,
      isTrue,
    );
  });

  testWidgets('1件だけ選んでいる間は確定できない(2件以上で確定できる)', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: DiarySelectPage(diaries: diaries, initialSelection: [diaries[0]]),
      ),
    );

    expect(find.text('日記を2件以上選んでください'), findsOneWidget);
    expect(
      tester.widget<ElevatedButton>(find.byType(ElevatedButton)).onPressed,
      isNull,
    );

    await tester.tap(find.text('この月をすべて選択').first);
    await tester.pump();

    expect(find.text('日記を2件以上選んでください'), findsNothing);
    expect(
      tester.widget<ElevatedButton>(find.byType(ElevatedButton)).onPressed,
      isNotNull,
    );
  });
}
