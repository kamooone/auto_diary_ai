import 'package:auto_diary_ai/features/ai/application/providers/ai_model_provider.dart';
import 'package:auto_diary_ai/features/ai/application/providers/ai_provider.dart';
import 'package:auto_diary_ai/features/ai/domain/entities/ai_message_request.dart';
import 'package:auto_diary_ai/features/ai/domain/entities/ai_reply.dart';
import 'package:auto_diary_ai/features/ai/domain/repositories/ai_repository.dart';
import 'package:auto_diary_ai/features/diary/domain/entities/diary.dart';
import 'package:auto_diary_ai/features/diary_create/application/providers/diary_usecase_providers.dart';
import 'package:auto_diary_ai/features/diary_create/domain/entities/summary_style.dart';
import 'package:auto_diary_ai/features/diary_create/domain/repositories/summary_style_repository.dart';
import 'package:auto_diary_ai/features/diary_create/presentation/providers/diary_create_provider.dart';
import 'package:auto_diary_ai/features/diary_create/presentation/ui/diary_result_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FixedAi implements AiRepository {
  @override
  Future<AiReply> sendMessage(AiMessageRequest request) async {
    return AiReply(answer: 'タイトル: 秋の一日\n本文:\nゆっくり過ごした。');
  }
}

class _MemoryStyleRepository implements SummaryStyleRepository {
  @override
  Future<SummaryStyle> load() async => SummaryStyle.reading;

  @override
  Future<void> save(SummaryStyle style) async {}
}

Diary _diary(int day) => Diary(
  date: DateTime(2026, 1, day),
  title: 't$day',
  content: 'c$day',
  isAiGenerated: false,
  createdAt: DateTime(2026, 1, day),
);

void main() {
  // AIが日記を書き終えた状態で、確認画面を開く(ホーム → 確認画面)
  Future<ProviderContainer> openResult(
    WidgetTester tester, {
    bool generate = true,
  }) async {
    final container = ProviderContainer(
      overrides: [
        aiRepositoryProvider.overrideWithValue(_FixedAi()),
        summaryStyleRepositoryProvider.overrideWithValue(
          _MemoryStyleRepository(),
        ),
      ],
    );
    addTearDown(container.dispose);
    container.listen(diaryCreateProvider, (_, __) {});
    // 使うAIの種類を読んでおく(確認画面が、作成中の表示で使う)
    container.read(aiModelProvider);

    if (generate) {
      final viewModel = container.read(diaryCreateProvider.notifier);
      viewModel.setSummaryDiaries([_diary(1), _diary(2)]);
      await viewModel.generateSummaryDiary();
    }

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: TextButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const DiaryResultScreen(),
                    ),
                  ),
                  child: const Text('確認画面を開く'),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('確認画面を開く'));
    await tester.pumpAndSettle();

    return container;
  }

  testWidgets('書き終えたあと、AppBarの戻るボタンを押すと、確認が出る', (tester) async {
    await openResult(tester);
    expect(find.text('AI日記の確認'), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();

    expect(find.text('本当に戻りますか？'), findsOneWidget);
    // まだ、確認画面のまま
    expect(find.text('AI日記の確認'), findsOneWidget);
  });

  testWidgets('端末の戻るボタンを押しても、確認が出る', (tester) async {
    await openResult(tester);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(find.text('本当に戻りますか？'), findsOneWidget);
    expect(find.text('AI日記の確認'), findsOneWidget);
  });

  testWidgets('「この画面に残る」を選ぶと、確認画面のまま', (tester) async {
    await openResult(tester);

    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.text('この画面に残る'));
    await tester.pumpAndSettle();

    expect(find.text('本当に戻りますか？'), findsNothing);
    expect(find.text('AI日記の確認'), findsOneWidget);
  });

  testWidgets('「戻る」を選ぶと、前の画面に戻る', (tester) async {
    await openResult(tester);

    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.text('戻る'));
    await tester.pumpAndSettle();

    expect(find.text('AI日記の確認'), findsNothing);
    expect(find.text('確認画面を開く'), findsOneWidget);
  });

  testWidgets('書いている途中は、確認なしで戻れる(書けたものがまだないため)', (tester) async {
    // まだ書いていない(生成していない)状態
    await openResult(tester, generate: false);

    await tester.pageBack();
    await tester.pumpAndSettle();

    expect(find.text('本当に戻りますか？'), findsNothing);
    expect(find.text('確認画面を開く'), findsOneWidget);
  });
}
