import 'package:auto_diary_ai/features/diary_create/domain/services/month_filter.dart';
import 'package:auto_diary_ai/features/diary_create/presentation/ui/widgets/month_filter_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final times = [
    DateTime(2025, 12, 31),
    DateTime(2026, 1, 5),
    DateTime(2026, 1, 20),
    DateTime(2026, 3, 1),
  ];

  test('年と月で絞り込める', () {
    expect(times.where(const MonthFilter(year: 2026).matches).length, 3);
    expect(
      times.where(const MonthFilter(year: 2026, month: 1).matches).length,
      2,
    );
    expect(times.where(MonthFilter.none.matches).length, 4);
  });

  test('選択肢は新しい順で、年に存在する月だけ', () {
    expect(MonthFilter.yearsOf(times), [2026, 2025]);
    expect(MonthFilter.monthsOf(times, 2026), [3, 1]);
  });

  test('年を変えると月の指定は解除される', () {
    final filter = const MonthFilter(year: 2026, month: 1).withYear(2025);
    expect(filter.month, isNull);
  });

  testWidgets('1つの月しかなくても表示する', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: MonthFilterBar(
          times: [DateTime(2026, 1, 1), DateTime(2026, 1, 9)],
          value: MonthFilter.none,
          onChanged: (_) {},
        ),
      ),
    ));
    expect(find.byKey(const Key('filterYear')), findsOneWidget);
  });

  testWidgets('年と月を選ぶと通知される', (tester) async {
    var value = MonthFilter.none;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: StatefulBuilder(
          builder: (context, setState) => MonthFilterBar(
            times: times,
            value: value,
            onChanged: (v) => setState(() => value = v),
          ),
        ),
      ),
    ));

    await tester.tap(find.byKey(const Key('filterYear')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('2026年').last);
    await tester.pumpAndSettle();
    expect(value.year, 2026);

    await tester.tap(find.byKey(const Key('filterMonth-2026')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('1月').last);
    await tester.pumpAndSettle();
    expect(value.month, 1);
  });
}
