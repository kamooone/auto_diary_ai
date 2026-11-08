import 'package:auto_diary_ai/features/ai/application/providers/ai_provider.dart';
import 'package:auto_diary_ai/features/ai/domain/entities/ai_message_request.dart';
import 'package:auto_diary_ai/features/ai/domain/entities/ai_reply.dart';
import 'package:auto_diary_ai/features/ai/domain/repositories/ai_repository.dart';
import 'package:auto_diary_ai/features/diary/domain/entities/diary.dart';
import 'package:auto_diary_ai/features/diary_create/application/providers/diary_usecase_providers.dart';
import 'package:auto_diary_ai/features/diary_create/domain/entities/summary_style.dart';
import 'package:auto_diary_ai/features/diary_create/domain/repositories/summary_style_repository.dart';
import 'package:auto_diary_ai/features/diary_create/presentation/providers/diary_create_provider.dart';
import 'package:auto_diary_ai/features/diary_create/presentation/viewmodel/diary_create_view_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class FixedAi implements AiRepository {
  FixedAi(this.modelName);

  /// サーバーが返したモデルの名前(返さないときはnull)
  final String? modelName;

  @override
  Future<AiReply> sendMessage(AiMessageRequest request) async {
    return AiReply(answer: 'タイトル: t\n本文:\nb', modelName: modelName);
  }
}

class MemoryStyleRepository implements SummaryStyleRepository {
  SummaryStyle saved = SummaryStyle.reading;

  @override
  Future<SummaryStyle> load() async => saved;

  @override
  Future<void> save(SummaryStyle style) async => saved = style;
}

Diary diary(int day) => Diary(
  date: DateTime(2026, 1, day),
  title: 't$day',
  content: 'c$day',
  isAiGenerated: false,
  createdAt: DateTime(2026, 1, day),
);

void main() {
  Future<DiaryCreateState> generate(String? modelName, {SummaryStyle? style}) async {
    final container = ProviderContainer(
      overrides: [
        aiRepositoryProvider.overrideWithValue(FixedAi(modelName)),
        summaryStyleRepositoryProvider.overrideWithValue(MemoryStyleRepository()),
      ],
    );
    addTearDown(container.dispose);
    container.listen(diaryCreateProvider, (_, __) {});

    final viewModel = container.read(diaryCreateProvider.notifier);
    viewModel.setSummaryDiaries([diary(1), diary(2)]);
    if (style != null) viewModel.setSummaryStyle(style);
    await viewModel.generateSummaryDiary();

    return container.read(diaryCreateProvider);
  }

  test('サーバーが教えてくれたモデルの名前を、使用したモデルとして持つ', () async {
    final state = await generate('gemini-flash-lite-latest');

    expect(state.generatedModel, 'gemini-flash-lite-latest');
    expect(state.generatedByAi, isTrue);
  });

  test('予備のモデルが書いたときは、予備のモデルの名前になる', () async {
    final state = await generate('gemini-2.5-flash-lite');

    expect(state.generatedModel, 'gemini-2.5-flash-lite');
  });

  test('サーバーが教えてくれないときは、選んでいるAIのモデルの名前にする', () async {
    final state = await generate(null);

    // 何も選んでいなければ Gemini
    expect(state.generatedModel, 'gemini-flash-lite-latest');
  });

  test('AIを使わない日記(連結)は、モデルの名前を持たない', () async {
    final state = await generate('x', style: SummaryStyle.chronicle);

    expect(state.generatedByAi, isFalse);
    expect(state.generatedModel, '');
  });
}
