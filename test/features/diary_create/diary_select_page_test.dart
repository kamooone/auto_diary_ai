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

    expect(find.text('この日をすべて選択'), findsNothing);
    expect(find.text('2026年1月1日（木）'), findsOneWidget);
  });
}
