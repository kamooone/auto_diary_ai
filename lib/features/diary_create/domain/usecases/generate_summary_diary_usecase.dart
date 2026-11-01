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
あなたは、日記を書いた本人になりきって文章を書くAIです。

以下は、ユーザー本人が書いた${diaries.length}件の日記です(日付の古い順)。
これらの内容をすべて使って、1つの日記として書き直してください。あわせて、その内容に合ったタイトルも書いてください。

書き方
・要約はしないでください。すべての日記の内容を、省略せずに含めてください。どの日の出来事も、場所、人、食べたもの、したこと、気持ちなどの具体的な内容を、そのまま残してください。
・日付の順に、「○月○日」と日付を示しながら、時間の流れに沿って書いてください。日ごとに段落を分けてください。
・本人が書いた日記として、「私は〜」「〜した」のように、素直な言葉で書いてください。
・元の日記にない出来事、気持ち、感想は、付け足さないでください。
・全体を振り返るまとめの感想や、「充実した日々だった」のような決まり文句は、書かないでください。
・長さは決めません。日記の量に合わせて、必要なだけ書いてください。

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
