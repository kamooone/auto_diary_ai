import '../../../ai/domain/entities/ai_message_request.dart';
import '../../../ai/domain/repositories/ai_repository.dart';
import '../../../diary/domain/entities/diary.dart';
import '../../../plan/domain/entities/plan_type.dart';
import '../entities/generated_diary.dart';
import '../services/generated_diary_parser.dart';
import '../services/summary_text.dart';

/// 作成済みの日記を複数まとめて、1つの日記(月のまとめ・1年の振り返りなど)にする
class GenerateSummaryDiaryUseCase {
  final AiRepository _aiRepository;

  final GeneratedDiaryParser _parser = GeneratedDiaryParser();

  GenerateSummaryDiaryUseCase({required AiRepository aiRepository})
    : _aiRepository = aiRepository;

  /// [diaries]は、まとめる日記(並び順は問わない)
  /// [note]はユーザーがAIに追加で伝えたい内容(なければ空文字)
  Future<GeneratedDiary> execute({
    required List<Diary> diaries,
    required String note,
    PlanType plan = PlanType.free,
  }) async {
    final request = AiMessageRequest(
      plan: plan,
      message:
          """
あなたは優秀な日記作成AIです。

以下は、ユーザーが書いた${diaries.length}件の日記です(日付の古い順)。
これらをまとめて、期間全体を振り返る1つの日記と、その内容に合ったタイトルを書いてください。

・出来事を1つずつ並べるのではなく、期間全体の流れ、印象に残った出来事、気持ちの変化をまとめてください。
・日記にないことは書かないでください。
・長さは${SummaryText.lengthGuide(diaries.length)}にしてください。

ユーザーが追加で伝えたいこと
${note.trim().isEmpty ? "(なし)" : note.trim()}

日記
${SummaryText.format(diaries)}

回答は必ず次の形式で書いてください。前置きや説明、記号による装飾は付けないでください。

タイトル: (日記のタイトルを1行で)
本文:
(日記の本文)
""",
      images: const [],
    );
    final reply = await _aiRepository.sendMessage(request);

    final diary = _parser.parse(reply.answer);

    return GeneratedDiary(
      title: diary.title,
      content: diary.content,
      usage: reply.usage,
    );
  }
}
