import 'package:auto_diary_ai/features/home/presentation/ui/widgets/year_month_dropdown.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // 新しい月が先頭
  const months = ['2026-10', '2026-03', '2025-12', '2025-01'];

  Future<void> open(
    WidgetTester tester, {
    required String selected,
    required List<String> changes,
  }) {
    return tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: YearMonthDropdown(
            months: months,
            selectedMonth: selected,
            onChanged: changes.add,
          ),
        ),
      ),
    );
  }

  testWidgets('年と月の2つのドロップダウンに、選択中の年月が出る', (tester) async {
    await open(tester, selected: '2026-03', changes: []);

    expect(find.text('年'), findsOneWidget);
    expect(find.text('月'), findsOneWidget);
    expect(find.text('2026年'), findsOneWidget);
    expect(find.text('3月'), findsOneWidget);
  });

  testWidgets('年を選ぶと、その年で一番新しい月になる', (tester) async {
    final changes = <String>[];
    await open(tester, selected: '2026-10', changes: changes);

    await tester.tap(find.byKey(const Key('homeYear')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('2025年').last);
    await tester.pumpAndSettle();

    expect(changes, ['2025-12']);
  });

  testWidgets('月の選択肢は、選択中の年にある月だけで、月を選ぶとその月になる', (tester) async {
    final changes = <String>[];
    await open(tester, selected: '2026-10', changes: changes);

    await tester.tap(find.byKey(const Key('homeMonth-2026')));
    await tester.pumpAndSettle();

    expect(find.text('1月'), findsNothing);
    expect(find.text('3月'), findsOneWidget);

    await tester.tap(find.text('3月').last);
    await tester.pumpAndSettle();

    expect(changes, ['2026-03']);
  });
}
