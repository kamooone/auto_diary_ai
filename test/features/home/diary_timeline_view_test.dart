import 'package:auto_diary_ai/features/diary/domain/entities/diary.dart';
import 'package:auto_diary_ai/features/home/presentation/ui/widgets/diary_timeline_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Diary diary(int day, {int hour = 9, bool ai = false, String? title}) => Diary(
  date: DateTime(2026, 10, day, hour),
  title: title ?? '日記$day',
  content: '',
  isAiGenerated: ai,
  createdAt: DateTime(2026, 10, day, hour),
);

void main() {
  Future<void> open(WidgetTester tester, List<Diary> items) {
    return tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DiaryTimelineView(
            months: const ['2026-10'],
            itemsPerMonth: {'2026-10': items},
            pageController: PageController(),
            onPageChanged: (_) {},
          ),
        ),
      ),
    );
  }

  testWidgets('日付と曜日、見出しが出て、最後に月のはじまりが出る', (tester) async {
    await open(tester, [diary(27), diary(26), diary(25), diary(24)]);
    await tester.pumpAndSettle();

    // 2026/10/27 は火曜日、25日は日曜日
    expect(find.text('27'), findsOneWidget);
    expect(find.text('火'), findsOneWidget);
    expect(find.text('日記27'), findsOneWidget);
    expect(find.text('10月のはじまり'), findsOneWidget);
  });

  testWidgets('AIが書いた日記には、AIの印が出る', (tester) async {
    await open(tester, [diary(27, ai: true), diary(26), diary(25), diary(24)]);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('aiChip')), findsOneWidget);
  });

  testWidgets('同じ日の2件目の日記は、日付を出さない', (tester) async {
    await open(tester, [
      diary(27),
      diary(26, hour: 20, title: '夜'),
      diary(26, hour: 8, title: '朝'),
      diary(25),
    ]);
    await tester.pumpAndSettle();

    expect(find.text('26'), findsOneWidget);
    expect(find.text('夜'), findsOneWidget);
    expect(find.text('朝'), findsOneWidget);
  });

  testWidgets('日記を書いた日が3日以下の月には、はげましの一文が出る', (tester) async {
    await open(tester, [diary(27), diary(26)]);
    await tester.pumpAndSettle();

    expect(find.textContaining('あなたの軌跡になっていきます'), findsOneWidget);
  });

  testWidgets('日記を書いた日が4日以上の月には、はげましの一文が出ない', (tester) async {
    await open(tester, [diary(27), diary(26), diary(25), diary(24)]);
    await tester.pumpAndSettle();

    expect(find.textContaining('あなたの軌跡になっていきます'), findsNothing);
  });

  testWidgets('見出しが長いときは、2行までにして、省略する', (tester) async {
    final long = '長い見出し' * 30;
    await open(tester, [
      diary(27, title: long),
      diary(26),
      diary(25),
      diary(24),
    ]);
    await tester.pumpAndSettle();

    final text = tester.widget<Text>(find.text(long));
    expect(text.maxLines, 2);
    expect(text.overflow, TextOverflow.ellipsis);
  });
}
