import 'package:auto_diary_ai/features/home/presentation/ui/widgets/home_month_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // 新しい月が先頭
  const months = ['2026-10', '2026-03', '2025-12', '2025-01'];

  Future<void> open(
    WidgetTester tester, {
    required String selected,
    required List<String> changes,
    int days = 5,
  }) {
    return tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: HomeMonthBar(
            months: months,
            selectedMonth: selected,
            recordedDays: days,
            onChanged: changes.add,
          ),
        ),
      ),
    );
  }

  testWidgets('選んでいる年月と、記録の日数が出る', (tester) async {
    await open(tester, selected: '2026-03', changes: [], days: 4);

    expect(find.text('2026年'), findsOneWidget);
    expect(find.text('3月'), findsOneWidget);
    expect(find.textContaining('記録 4日'), findsOneWidget);
  });

  testWidgets('左右のボタンで、日記のある月を、ひとつずつ移る', (tester) async {
    final changes = <String>[];
    await open(tester, selected: '2026-03', changes: changes);

    await tester.tap(find.byKey(const Key('homePreviousMonth')));
    await tester.tap(find.byKey(const Key('homeNextMonth')));

    // 左が古い月、右が新しい月(日記のない月は、飛ばす)
    expect(changes, ['2025-12', '2026-10']);
  });

  testWidgets('いちばん新しい月では右、いちばん古い月では左のボタンが、押せない', (tester) async {
    final changes = <String>[];
    await open(tester, selected: '2026-10', changes: changes);
    await tester.tap(find.byKey(const Key('homeNextMonth')));
    expect(changes, isEmpty);

    await open(tester, selected: '2025-01', changes: changes);
    await tester.tap(find.byKey(const Key('homePreviousMonth')));
    expect(changes, isEmpty);
  });

  testWidgets('年月を押すと、シートが出て、日記のある月を選べる', (tester) async {
    final changes = <String>[];
    await open(tester, selected: '2026-10', changes: changes);

    await tester.tap(find.byKey(const Key('homeMonthLabel')));
    await tester.pumpAndSettle();

    // 日記のない月は、押しても、何も起きない
    await tester.tap(find.byKey(const Key('sheetMonth-2026-05')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('sheetMonth-2026-03')), findsOneWidget);
    expect(changes, isEmpty);

    await tester.tap(find.byKey(const Key('sheetMonth-2026-03')));
    await tester.pumpAndSettle();

    expect(changes, ['2026-03']);
    expect(find.byKey(const Key('sheetMonth-2026-03')), findsNothing);
  });

  testWidgets('シートで年を切り替えて、その年の月を選べる', (tester) async {
    final changes = <String>[];
    await open(tester, selected: '2026-10', changes: changes);

    await tester.tap(find.byKey(const Key('homeMonthLabel')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('sheetPreviousYear')));
    await tester.pumpAndSettle();

    expect(find.text('2025年'), findsOneWidget);

    await tester.tap(find.byKey(const Key('sheetMonth-2025-12')));
    await tester.pumpAndSettle();

    expect(changes, ['2025-12']);
  });
}
