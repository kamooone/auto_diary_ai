import '../../../diary/domain/entities/diary.dart';
import '../../../memo/domain/entities/memo.dart';
import '../../../memo/domain/services/memo_text.dart';
import '../entities/diary_style.dart';
import '../entities/summary_style.dart';
import 'consult_message.dart';
import 'summary_text.dart';

/// AIに渡す文章の、材料と設定(サーバーに送る内容)
///
/// 指示の文章と組み立ては、サーバー(server/ai_chat/diary_prompts.py)が持つ。
/// アプリは、行動履歴・Xの投稿・日記を文章にしたものと、設定(書き方・文字数の目安など)だけを渡す。
/// キーの名前は、サーバーと合わせてある(変えるときは、サーバーも直す)。
class PromptSpec {
  const PromptSpec._();

  /// ふつうのAI日記
  ///
  /// [timelineText]は行動履歴、[postsText]はXの投稿を、文章にしたもの。
  /// [memos]は、選んだひとことメモ(文章にして、`memosText`で送る)
  static Map<String, Object?> diary({
    required DiaryStyle style,
    required String customInstruction,
    required int lengthChars,
    required DateTime diaryDate,
    required DateTime startDate,
    required DateTime endDate,
    required String note,
    required String timelineText,
    required String postsText,
    List<Memo> memos = const [],
  }) {
    return {
      'kind': 'diary',
      'style': style.name,
      'customInstruction': customInstruction,
      'lengthChars': lengthChars,
      'diaryDate': _ymd(diaryDate),
      'startDate': _ymd(startDate),
      'endDate': _ymd(endDate),
      'note': note,
      'timelineText': timelineText,
      'postsText': postsText,
      'memosText': MemoText.format(memos),
    };
  }

  /// 日記を1つにする
  static Map<String, Object?> summary({
    required SummaryStyle style,
    required List<Diary> diaries,
    required String note,
    required String customInstruction,
    required int lengthChars,
  }) {
    return {
      'kind': 'summary',
      'style': style.name,
      'customInstruction': customInstruction,
      'lengthChars': lengthChars,
      'note': note,
      'diaryCount': diaries.length,
      'diariesText': SummaryText.formatForAi(diaries),
      'diariesChars': SummaryText.length(diaries),
    };
  }

  /// 書き方の相談(最初。日記の全文を渡す)
  static Map<String, Object?> consultFirst(List<Diary> diaries) {
    return {
      'kind': 'consult_first',
      'diaryCount': diaries.length,
      'diariesText': SummaryText.format(diaries),
    };
  }

  /// 書き方の相談(続き。日記の全文は渡さず、材料メモと会話を渡す)
  static Map<String, Object?> consultFollowUp({
    required String brief,
    required List<ConsultMessage> history,
    required String message,
  }) {
    return {
      'kind': 'consult_follow_up',
      'brief': brief,
      'history': [
        for (final e in history)
          {
            'fromUser': e.fromUser,
            'text': e.text,
            if (e.proposal != null) 'proposal': e.proposal,
          },
      ],
      'message': message,
    };
  }

  // 「2026-01-05」の形
  static String _ymd(DateTime d) {
    final month = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');

    return "${d.year.toString().padLeft(4, '0')}-$month-$day";
  }
}
