import 'package:auto_diary_ai/features/ai/domain/entities/ai_message_request.dart';
import 'package:auto_diary_ai/features/ai/domain/entities/ai_reply.dart';
import 'package:auto_diary_ai/features/ai/domain/repositories/ai_repository.dart';
import 'package:auto_diary_ai/features/diary/domain/entities/diary.dart';
import 'package:auto_diary_ai/features/diary_create/domain/entities/photo.dart';
import 'package:auto_diary_ai/features/diary_create/domain/repositories/photo_repository.dart';
import 'package:auto_diary_ai/features/diary_create/domain/services/summary_rules.dart';
import 'package:auto_diary_ai/features/diary_create/domain/usecases/generate_diary_usecase.dart';
import 'package:auto_diary_ai/features/diary_create/domain/usecases/generate_summary_diary_usecase.dart';
import 'package:flutter_test/flutter_test.dart';

class CapturingAi implements AiRepository {
  String? message;

  @override
  Future<AiReply> sendMessage(AiMessageRequest request) async {
    message = request.message;
    return const AiReply(answer: 'タイトル: t\n本文:\nb');
  }
}

class NoPhotos implements PhotoRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

void main() {
  const marker = '複数日の情報をまとめた日記を書くときの書き方';
  final rule = SummaryRules.text().split('\n').first;

  Future<String> normal(DateTime start, DateTime end) async {
    final ai = CapturingAi();
    await GenerateDiaryUseCase(aiRepository: ai, photoRepository: NoPhotos())
        .execute(
          note: '',
          diaryDate: end,
          startDate: start,
          endDate: end,
          photos: const <Photo>[],
          timeline: const [],
          posts: const [],
        );
    return ai.message!;
  }

  test('ふつうの日記は、1日分ならまとめの書き方を付けない', () async {
    final message = await normal(DateTime(2026, 1, 1), DateTime(2026, 1, 1));

    expect(message, isNot(contains(marker)));
  });

  test('ふつうの日記は、複数日ならまとめの書き方を付ける', () async {
    final message = await normal(DateTime(2026, 1, 1), DateTime(2026, 1, 7));

    expect(message, contains(marker));
    expect(message, contains(rule));
  });

  test('日記を1つにするときは、形をAIに判断させ、日記の内容と長さの目安を渡す', () async {
    final ai = CapturingAi();
    await GenerateSummaryDiaryUseCase(aiRepository: ai).execute(
      note: '',
      diaries: [
        for (var i = 1; i <= 2; i++)
          Diary(
            date: DateTime(2026, 1, i),
            title: 't$i',
            content: 'c$i',
            isAiGenerated: false,
            createdAt: DateTime(2026, 1, i),
          ),
      ],
    );

    expect(ai.message, contains('一番読みやすい形を判断'));
    expect(ai.message, contains('章立て'));
    expect(ai.message, contains('2026年1月1日 t1\nc1'));
    expect(ai.message, contains('長さの目安は300〜500文字'));
  });
}
