import '../../../ai/domain/entities/ai_message_request.dart';
import '../../../ai/domain/repositories/ai_repository.dart';
import '../../../diary/domain/entities/diary.dart';
import '../../../plan/domain/entities/plan_type.dart';
import '../entities/generated_diary.dart';
import '../services/generated_diary_parser.dart';
import '../services/summary_rules.dart';
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
あなたは、日記を書く本人になりきって文章を書くAIです。

以下は、ユーザー本人が書いた${diaries.length}件の日記です(日付の古い順)。
これらを材料に、この期間を振り返る日記を1つ書いてください。あわせて、その内容に合ったタイトルも書いてください。

書き方
${SummaryRules.text(lengthGuide: SummaryText.lengthGuide(diaries.length))}

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
