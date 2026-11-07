import '../../../ai/domain/entities/ai_message_request.dart';
import '../../../ai/domain/repositories/ai_repository.dart';
import '../../../diary/domain/entities/diary.dart';
import '../../../plan/domain/entities/plan_type.dart';
import '../entities/generated_diary.dart';
import '../entities/summary_style.dart';
import '../services/generated_diary_parser.dart';
import '../services/summary_prompt.dart';

/// 作成済みの日記を複数選んで、1つの日記にする
class GenerateSummaryDiaryUseCase {
  final AiRepository _aiRepository;

  final GeneratedDiaryParser _parser = GeneratedDiaryParser();

  GenerateSummaryDiaryUseCase({required AiRepository aiRepository})
    : _aiRepository = aiRepository;

  /// [diaries]は、1つにする日記(並び順は問わない)
  /// [style]は書き方。[style]が自分で指定のときは、[customInstruction]に書き方の指示を渡す
  /// [note]はユーザーがAIに追加で伝えたい内容(なければ空文字)
  Future<GeneratedDiary> execute({
    required List<Diary> diaries,
    required String note,
    SummaryStyle style = SummaryStyle.reading,
    String customInstruction = '',
    PlanType plan = PlanType.free,
    int lengthChars = 0,
  }) async {
    final request = AiMessageRequest(
      plan: plan,
      message: SummaryPrompt.build(
        style: style,
        diaries: diaries,
        note: note,
        customInstruction: customInstruction,
        lengthChars: lengthChars,
      ),
      images: const [],
    );
    final reply = await _aiRepository.sendMessage(request);

    final diary = _parser.parse(reply.answer);

    return GeneratedDiary(
      title: diary.title,
      content: diary.content,
      usage: reply.usage,
      modelName: reply.modelName,
    );
  }
}
