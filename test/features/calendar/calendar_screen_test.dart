import 'package:auto_diary_ai/common/constants/app_colors.dart';
import 'package:auto_diary_ai/features/calendar/presentation/ui/calendar_screen.dart';
import 'package:auto_diary_ai/features/diary/application/providers/diary_providers.dart';
import 'package:auto_diary_ai/features/diary/domain/entities/diary.dart';
import 'package:auto_diary_ai/features/tutorial/application/tutorial_providers.dart';
import 'package:auto_diary_ai/features/tutorial/data/tutorial_seen_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _SeenStore implements TutorialSeenStore {
  @override
  Future<bool> hasSeen(String id) async => true;

  @override
  Future<void> markSeen(String id) async {}

  @override
  Future<void> clearAll() async {}
}

Diary diary(DateTime date, String title, {bool ai = false}) => Diary(
  date: date,
  title: title,
  content: '',
  isAiGenerated: ai,
  createdAt: date,
);

void main() {
  final now = DateTime.now();
  final thisMonth = DateTime(now.year, now.month);

  Future<void> open(WidgetTester tester, List<Diary> diaries) async {
    tester.view.physicalSize = const Size(1080, 2200);
    tester.view.devicePixelRatio = 2.6;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          tutorialSeenStoreProvider.overrideWithValue(_SeenStore()),
          diariesProvider.overrideWith((ref) => Stream.value(diaries)),
        ],
        child: const MaterialApp(home: CalendarScreen()),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('年月の下に、記録の日数は出ない。マスの下に、説明の行も出ない', (tester) async {
    await open(tester, [
      diary(thisMonth, '月初め'),
      diary(DateTime(thisMonth.year, thisMonth.month, 1, 20), '月初めの夜'),
    ]);

    expect(find.byKey(const Key('homeRecordedDays')), findsNothing);
    expect(find.textContaining('記録 '), findsNothing);
    expect(find.text('記録した日'), findsNothing);
    expect(find.text('いちばん新しい記録'), findsNothing);
    expect(find.text('ほかの日記の数'), findsNothing);
  });

  testWidgets('同じ日に複数あるときは、1件目のタイトルと、「+1」が出る', (tester) async {
    await open(tester, [
      diary(DateTime(thisMonth.year, thisMonth.month, 1, 9), '朝'),
      diary(DateTime(thisMonth.year, thisMonth.month, 1, 20), '夜'),
    ]);

    expect(find.text('朝'), findsOneWidget);
    expect(find.text('夜'), findsNothing);
    expect(find.text('+1'), findsOneWidget);
    final semantics = tester.ensureSemantics();
    await tester.pump();
    expect(find.bySemanticsLabel(RegExp('ほかに1件')), findsWidgets);
    semantics.dispose();
  });

  testWidgets('いちばん新しい記録の日だけ、オレンジの丸になる', (tester) async {
    await open(tester, [
      diary(DateTime(thisMonth.year, thisMonth.month, 1), '古い'),
      diary(DateTime(thisMonth.year, thisMonth.month, 2), '新しい'),
    ]);

    final latest = find.byKey(const Key('latestDay'));
    expect(latest, findsOneWidget);
    expect(
      find.descendant(of: latest, matching: find.text('2')),
      findsOneWidget,
    );

    final decoration =
        tester.widget<Container>(latest).decoration as BoxDecoration;
    expect(decoration.color, AppColors.orange);
  });

  testWidgets('日記がない日は、押せない。ある日を押すと、日記が開く', (tester) async {
    await open(tester, [
      diary(DateTime(thisMonth.year, thisMonth.month, 1, 9), '朝'),
      diary(DateTime(thisMonth.year, thisMonth.month, 1, 20), '夜', ai: true),
    ]);

    // 複数あるときは、その日の一覧が出る
    await tester.tap(find.text('朝'));
    await tester.pumpAndSettle();

    expect(find.textContaining('の日記(2件)'), findsOneWidget);
    expect(find.text('夜'), findsOneWidget);
    expect(find.text('AI'), findsOneWidget);
  });

  testWidgets('戻る、前の月、次の月のボタンに、読み上げ用の名前が付く', (tester) async {
    await open(tester, [
      diary(DateTime(thisMonth.year, thisMonth.month - 1, 5), '先月'),
    ]);

    expect(find.byTooltip('戻る'), findsOneWidget);
    expect(find.byTooltip('前の月'), findsOneWidget);
    expect(find.byTooltip('次の月'), findsOneWidget);
  });

  testWidgets('前の月のボタンで、先月に移る。「今日」で、今月に戻る', (tester) async {
    await open(tester, [
      diary(DateTime(thisMonth.year, thisMonth.month - 1, 5), '先月の日記'),
    ]);

    expect(find.text('先月の日記'), findsNothing);

    await tester.tap(find.byKey(const Key('homePreviousMonth')));
    await tester.pumpAndSettle();
    expect(find.text('先月の日記'), findsOneWidget);

    await tester.tap(find.text('今日'));
    await tester.pumpAndSettle();
    expect(find.text('先月の日記'), findsNothing);
  });

  testWidgets('今日の日付には、オレンジの輪が付く', (tester) async {
    await open(tester, const []);

    final today = find.byKey(const Key('todayDay'));
    expect(today, findsOneWidget);
    expect(
      find.descendant(of: today, matching: find.text('${now.day}')),
      findsOneWidget,
    );

    final decoration =
        tester.widget<Container>(today).decoration as BoxDecoration;
    expect(decoration.shape, BoxShape.circle);
    expect((decoration.border as Border).top.color, AppColors.orange);
  });
}
