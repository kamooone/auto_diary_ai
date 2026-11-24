import 'package:auto_diary_ai/features/location/presentation/ui/activity_permission_explanation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<Future<bool> Function()> open(WidgetTester tester) async {
    late BuildContext context;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (c) {
            context = c;
            return const Scaffold(body: SizedBox.expand());
          },
        ),
      ),
    );
    return () => showActivityPermissionExplanation(context);
  }

  testWidgets('何のために使うのかを、移動の手段の例(自転車など)つきで説明する', (tester) async {
    final show = await open(tester);
    show();
    await tester.pumpAndSettle();

    expect(find.text('身体活動の許可について'), findsOneWidget);
    expect(find.textContaining('自転車に乗っている'), findsOneWidget);
    expect(find.textContaining('許可しなくても、行動履歴は使えます'), findsOneWidget);
  });

  testWidgets('「次へ」を押すと true(このあと、OSの許可のダイアログを出す)', (tester) async {
    final show = await open(tester);
    final result = show();
    await tester.pumpAndSettle();

    await tester.tap(find.text('次へ'));
    await tester.pumpAndSettle();

    expect(await result, isTrue);
  });

  testWidgets('「あとで」を押すと false(OSの許可のダイアログは出さない)', (tester) async {
    final show = await open(tester);
    final result = show();
    await tester.pumpAndSettle();

    await tester.tap(find.text('あとで'));
    await tester.pumpAndSettle();

    expect(await result, isFalse);
  });

  testWidgets('ダイアログの外を押しても、閉じない(説明を読まずに進めないようにする)', (tester) async {
    final show = await open(tester);
    show();
    await tester.pumpAndSettle();

    await tester.tapAt(const Offset(5, 5));
    await tester.pumpAndSettle();

    expect(find.text('身体活動の許可について'), findsOneWidget);
  });
}
