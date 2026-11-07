import 'package:auto_diary_ai/features/ai/domain/entities/ai_model.dart';
import 'package:auto_diary_ai/features/ai/presentation/widgets/ai_model_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('「違いを見る」に、モデルごとの書き上がる文章の傾向が出る', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: Scaffold(body: AiModelSelector())),
      ),
    );

    await tester.tap(find.text('違いを見る'));
    await tester.pumpAndSettle();

    expect(find.text('書き上がる文章: ${AiModel.gemini.writing}'), findsOneWidget);
    expect(find.text('書き上がる文章: ${AiModel.gpt.writing}'), findsOneWidget);
    expect(find.textContaining('日記にないことを付け足しにくい'), findsOneWidget);
    expect(find.textContaining('日記にない一言が入ることがある'), findsOneWidget);
  });

  test('Geminiの説明は、予備のモデルへの自動切り替えを約束しない', () {
    expect(AiModel.gemini.feature, isNot(contains('別のGeminiのモデルに自動')));
    expect(AiModel.gemini.feature, contains('やり直します'));
  });
}
