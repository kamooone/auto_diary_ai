import 'package:auto_diary_ai/features/plan/presentation/widgets/usage_limit_guidance.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> open(WidgetTester tester, UsageLimitGuidance widget) {
    return tester.pumpWidget(MaterialApp(home: Scaffold(body: widget)));
  }

  testWidgets('有料プランがない間は、来月に戻ることとポイントの案内で、プランという言葉は出ない', (tester) async {
    await open(tester, const UsageLimitGuidance(paidPlanAvailable: false));

    expect(find.textContaining('来月の初めに、枠が戻ります'), findsOneWidget);
    expect(find.text('ポイント・トークンを見る'), findsOneWidget);
    expect(find.textContaining('プラン'), findsNothing);
  });

  testWidgets('有料プランを出すとき、無料なら、プランを見るボタンが出る', (tester) async {
    await open(tester, const UsageLimitGuidance(paidPlanAvailable: true));

    expect(find.textContaining('有料プランにすると'), findsOneWidget);
    expect(find.text('プランを見る'), findsOneWidget);
  });

  testWidgets('有料プランを出すとき、有料なら、リセットまで使えない案内で、ボタンは出ない', (tester) async {
    await open(
      tester,
      const UsageLimitGuidance(paidPlanAvailable: true, isPaid: true),
    );

    expect(find.textContaining('次のリセットまで'), findsOneWidget);
    expect(find.text('プランを見る'), findsNothing);
  });

  testWidgets('今は、有料プランを出さない設定が初期値', (tester) async {
    await open(tester, const UsageLimitGuidance());

    expect(find.textContaining('プラン'), findsNothing);
  });
}
