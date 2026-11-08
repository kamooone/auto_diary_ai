import '../../../ai/domain/entities/ai_message_request.dart';
import '../../../ai/domain/repositories/ai_repository.dart';
import '../../../diary/domain/entities/diary.dart';
import '../../../plan/domain/entities/plan_type.dart';
import '../../../plan/domain/entities/usage_info.dart';
import '../services/consult_message.dart';
import '../services/prompt_spec.dart';
import '../services/consult_reply_parser.dart';
import '../services/summary_text.dart';

/// AIの返答と、この返答までの今月の使用量
class ConsultResult {
  const ConsultResult({required this.reply, this.usage});

  final ConsultReply reply;
  final UsageInfo? usage;
}

/// 「日記を1つにする」の書き方を、AIに相談する
class ConsultSummaryUseCase {
  final AiRepository _aiRepository;

  final ConsultReplyParser _parser = ConsultReplyParser();

  ConsultSummaryUseCase({required AiRepository aiRepository})
    : _aiRepository = aiRepository;

  /// 最初の相談。日記の全文を送る。返答には、これからの相談で使う材料メモが付く
  Future<ConsultResult> start({
    required List<Diary> diaries,
    PlanType plan = PlanType.free,
  }) async {
    final result = await _send(PromptSpec.consultFirst(diaries), plan);

    // AIが材料メモを付けなかったときは、タイトルの一覧で代わりにする
    final brief = result.reply.brief ?? fallbackBrief(diaries);

    return ConsultResult(
      reply: ConsultReply(
        text: result.reply.text,
        proposal: result.reply.proposal,
        brief: brief,
      ),
      usage: result.usage,
    );
  }

  /// 続けての相談。日記の全文は送らず、材料メモと会話だけを送る
  Future<ConsultResult> followUp({
    required String brief,
    required List<ConsultMessage> history,
    required String message,
    PlanType plan = PlanType.free,
  }) {
    return _send(
      PromptSpec.consultFollowUp(
        brief: brief,
        history: history,
        message: message,
      ),
      plan,
    );
  }

  Future<ConsultResult> _send(
    Map<String, Object?> prompt,
    PlanType plan,
  ) async {
    final reply = await _aiRepository.sendMessage(
      AiMessageRequest(plan: plan, prompt: prompt),
    );

    // 返答が空のときは、空の吹き出しを出さずに、失敗として扱う(画面から再送できる)
    if (reply.answer.trim().isEmpty) {
      throw StateError('AIの返答が空でした');
    }

    return ConsultResult(
      reply: _parser.parse(reply.answer),
      usage: reply.usage,
    );
  }

  /// 件数と、日付つきのタイトルの一覧
  static String fallbackBrief(List<Diary> diaries) {
    final sorted = SummaryText.sorted(diaries);
    final titles = sorted
        .map((e) => "${e.date.month}/${e.date.day} ${e.headline}")
        .join("\n");

    return "${diaries.length}件の日記。タイトルの一覧:\n$titles";
  }
}
