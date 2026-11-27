import 'package:auto_diary_ai/features/ai/application/providers/ai_provider.dart';
import 'package:auto_diary_ai/features/ai/domain/entities/ai_message_request.dart';
import 'package:auto_diary_ai/features/ai/domain/entities/ai_reply.dart';
import 'package:auto_diary_ai/features/ai/domain/exceptions/ai_exception.dart';
import 'package:auto_diary_ai/features/ai/domain/repositories/ai_repository.dart';
import 'package:auto_diary_ai/features/diary/domain/entities/diary.dart';
import 'package:auto_diary_ai/features/diary_create/domain/entities/summary_style.dart';
import 'package:auto_diary_ai/features/diary_create/domain/repositories/summary_style_repository.dart';
import 'package:auto_diary_ai/features/diary_create/application/providers/diary_usecase_providers.dart';
import 'package:auto_diary_ai/features/diary_create/presentation/providers/diary_create_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class BlockedAi implements AiRepository {
  @override
  Future<AiReply> sendMessage(AiMessageRequest request) async {
    throw ContentBlockedException();
  }
}

class MemoryStyleRepository implements SummaryStyleRepository {
  @override
  Future<SummaryStyle> load() async => SummaryStyle.reading;

  @override
  Future<void> save(SummaryStyle style) async {}
}

Diary diary(int day) => Diary(
  date: DateTime(2026, 1, day),
  title: 't$day',
  content: 'c$day',
  isAiGenerated: false,
  createdAt: DateTime(2026, 1, day),
);

void main() {
  test('AIに送れない内容が含まれていると断られたら、見直す案内を出す(生成)', () async {
    final container = ProviderContainer(
      overrides: [
        aiRepositoryProvider.overrideWithValue(BlockedAi()),
        summaryStyleRepositoryProvider.overrideWithValue(
          MemoryStyleRepository(),
        ),
      ],
    );
    addTearDown(container.dispose);
    container.listen(diaryCreateProvider, (_, __) {});

    final viewModel = container.read(diaryCreateProvider.notifier);
    viewModel.setSummaryDiaries([diary(1), diary(2)]);
    await viewModel.generateSummaryDiary();

    final state = container.read(diaryCreateProvider);
    expect(state.errorMessage, ContentBlockedException.message);
    expect(state.isLoading, isFalse);
    expect(state.generatedDiary.trim(), isEmpty);
  });
}
