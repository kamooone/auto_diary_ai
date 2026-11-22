import 'package:auto_diary_ai/features/ai/domain/entities/ai_model.dart';
import 'package:auto_diary_ai/features/ai/presentation/widgets/ai_select_card.dart';
import 'package:auto_diary_ai/features/plan/domain/entities/usage_info.dart';
import 'package:auto_diary_ai/features/privacy/presentation/ui/privacy_policy_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('「違いを見る」に、モデルごとの書き上がる文章の傾向が出る', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: Scaffold(body: AiSelectCard(usage: null))),
      ),
    );

    await tester.tap(find.text('違いを見る'));
    await tester.pumpAndSettle();

    expect(find.text(AiModel.gemini.writing), findsOneWidget);
    expect(find.text(AiModel.gpt.writing), findsOneWidget);
    expect(find.textContaining('日記にないことを付け足しにくい'), findsOneWidget);
    expect(find.textContaining('日記にない一言が入ることがある'), findsOneWidget);
  });

  Future<void> showUsage(WidgetTester tester, int tokenBalance) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: AiSelectCard(
              usage: UsageInfo(
                usedTokens: 1000,
                limitTokens: 10000,
                tokenBalance: tokenBalance,
              ),
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('ポイントで交換したトークンがあれば、残りと「無料枠を使い切ったあとに使われる」ことを出す', (tester) async {
    await showUsage(tester, 7000);

    expect(find.text('ポイントで交換したトークン 残り 7,000'), findsOneWidget);
    expect(find.textContaining('無料枠を使い切ったあとに'), findsOneWidget);
  });

  testWidgets('ポイントで交換したトークンがなければ、その行を出さない', (tester) async {
    await showUsage(tester, 0);

    expect(find.textContaining('ポイントで交換したトークン'), findsNothing);
    expect(find.textContaining('無料枠を使い切ったあとに'), findsNothing);
  });

  test('Geminiの説明は、予備のモデルへの自動切り替えを約束しない', () {
    expect(AiModel.gemini.feature, isNot(contains('別のGeminiのモデルに自動')));
    expect(AiModel.gemini.feature, contains('やり直します'));
  });

  testWidgets('「違いを見る」の、プライバシーポリシーの案内を押すと、その画面を開く', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: Scaffold(body: AiSelectCard(usage: null))),
      ),
    );

    await tester.tap(find.text('違いを見る'));
    await tester.pumpAndSettle();

    // シートの中は、スクロールできる(画面の外にあるリンクまで動かす)
    await tester.ensureVisible(find.text('詳しくは、プライバシーポリシーをご確認ください'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('詳しくは、プライバシーポリシーをご確認ください'));
    await tester.pumpAndSettle();

    expect(find.byType(PrivacyPolicyPage), findsOneWidget);
    expect(find.text('1. 基本的な考え方'), findsOneWidget);
  });
}
