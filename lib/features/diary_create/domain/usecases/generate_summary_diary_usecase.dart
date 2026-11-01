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
これらを材料に、この期間を1つの日記にした文章を書いてください。あわせて、その内容に合ったタイトルも書いてください。

形
材料を読んで、一番読みやすい形を判断してください。
・5件以下のとき、または似た出来事の繰り返しが中心で内容に幅がないときは、章立てにせず、日付の流れに沿った1本の文章にしてください。繰り返しは、「何度も」「ほぼ毎日」のように頻度でまとめてください。
・仕事、旅行、趣味、人付き合いなど、性格の違う出来事が混ざっているときは、テーマごとの章立てにしてください。章は、内容から自然に分かれる2〜6個にして、無理に作らないでください。章の見出しは、本文中に「1. 見出し」の形で書き、#や*などの記号は使わないでください。
・章立てにしても、章の中は時間の流れに沿って書いてください。

書き方
・本人が書いた日記として、「私は〜」「〜した」のように、素直な言葉で書いてください。元の日記の口調や言い回しも引き継いでください。
・要約しすぎないでください。場所、人、食べたもの、したこと、気持ちなどの具体的な細部を、できるだけ残してください。大きな出来事には、「○月○日」と日付を添えてください。
・同じことの繰り返しだけは、まとめてかまいません。
・元の日記にない出来事、気持ち、感想は、付け足さないでください。
・全体を振り返る感想や、「充実した日々だった」のような決まり文句は、書かないでください。
・長さの目安は${SummaryText.lengthGuide(SummaryText.length(diaries))}です。
・下の「ユーザーが追加で伝えたいこと」があれば、形や長さも含めて、それを最優先してください。

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
