import 'dart:convert';
import 'package:auto_diary_ai/features/ai/domain/entities/ai_message_request.dart';
import 'package:auto_diary_ai/features/ai/domain/entities/ai_reply.dart';
import 'package:auto_diary_ai/features/ai/domain/exceptions/ai_exception.dart';
import 'package:auto_diary_ai/features/plan/domain/entities/usage_info.dart';
import 'package:auto_diary_ai/features/ai/domain/repositories/ai_repository.dart';
import 'package:auto_diary_ai/features/diary/domain/entities/diary.dart';
import 'package:auto_diary_ai/features/diary_create/domain/entities/diary_style.dart';
import 'package:auto_diary_ai/features/diary_create/domain/entities/photo.dart';
import 'package:auto_diary_ai/features/diary_create/domain/entities/summary_style.dart';
import 'package:auto_diary_ai/features/diary_create/domain/repositories/photo_repository.dart';
import 'package:auto_diary_ai/features/diary_create/domain/services/consult_message.dart';
import 'package:auto_diary_ai/features/diary_create/domain/usecases/consult_summary_usecase.dart';
import 'package:auto_diary_ai/features/diary_create/domain/usecases/generate_diary_usecase.dart';
import 'package:auto_diary_ai/features/diary_create/domain/usecases/generate_summary_diary_usecase.dart';
import 'package:flutter_test/flutter_test.dart';

/// AIに渡す文章の指示は、サーバーが組み立てる(server/ai_chat/diary_prompts.py)。
/// アプリが送るのは、材料と設定だけ。ここでは、その内容を確かめる。
class CapturingAi implements AiRepository {
  CapturingAi({this.answer = 'タイトル: t\n本文:\nb\n【相談の回答】\nok'});

  final String answer;
  AiMessageRequest? request;

  Map<String, Object?> get prompt => request!.prompt;

  @override
  Future<AiReply> sendMessage(AiMessageRequest request) async {
    this.request = request;
    return AiReply(answer: answer);
  }
}

class NoPhotos implements PhotoRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

Diary diary(int day, String title, String content) => Diary(
  date: DateTime(2026, 1, day),
  title: title,
  content: content,
  isAiGenerated: false,
  createdAt: DateTime(2026, 1, day),
);

void main() {
  Future<CapturingAi> normal(
    DateTime start,
    DateTime end, {
    DateTime? diaryDate,
    DiaryStyle style = DiaryStyle.diary,
    String custom = '',
    int lengthChars = 0,
    String note = '',
  }) async {
    final ai = CapturingAi();
    await GenerateDiaryUseCase(aiRepository: ai, photoRepository: NoPhotos())
        .execute(
          note: note,
          diaryDate: diaryDate ?? end,
          startDate: start,
          endDate: end,
          photos: const <Photo>[],
          timeline: const [],
          posts: const [],
          style: style,
          customInstruction: custom,
          lengthChars: lengthChars,
        );
    return ai;
  }

  group('ふつうの日記', () {
    test('プロンプトの全文ではなく、材料と設定を送る', () async {
      final ai = await normal(
        DateTime(2026, 1, 1),
        DateTime(2026, 1, 7),
        diaryDate: DateTime(2026, 1, 8),
        style: DiaryStyle.blog,
        custom: '短く',
        lengthChars: 1000,
        note: '誕生日だった',
      );

      expect(ai.prompt, {
        'kind': 'diary',
        'style': 'blog',
        'customInstruction': '短く',
        'lengthChars': 1000,
        'diaryDate': '2026-01-08',
        'startDate': '2026-01-01',
        'endDate': '2026-01-07',
        'note': '誕生日だった',
        'timelineText': '',
        'postsText': '',
      });
    });

    test('日付は、月と日を2桁にして送る', () async {
      final ai = await normal(DateTime(2026, 9, 3), DateTime(2026, 9, 3));

      expect(ai.prompt['diaryDate'], '2026-09-03');
    });

    test('書き方は、名前で送る', () async {
      for (final style in DiaryStyle.values) {
        final ai = await normal(
          DateTime(2026, 1, 1),
          DateTime(2026, 1, 1),
          style: style,
        );

        expect(ai.prompt['style'], style.name);
      }
    });

    test('送る内容は、JSONにできる', () async {
      final ai = await normal(DateTime(2026, 1, 1), DateTime(2026, 1, 7));

      expect(jsonDecode(jsonEncode(ai.request!.prompt)), ai.prompt);
    });
  });

  group('日記を1つにする', () {
    test('日記を「■」で区切った文章と、件数・文字数・設定を送る', () async {
      final ai = CapturingAi();
      await GenerateSummaryDiaryUseCase(aiRepository: ai).execute(
        note: '仕事の話を中心に',
        diaries: [diary(2, 't2', 'c2'), diary(1, 't1', 'c1')],
        style: SummaryStyle.brief,
        customInstruction: '',
        lengthChars: 800,
      );

      expect(ai.prompt['kind'], 'summary');
      expect(ai.prompt['style'], 'brief');
      expect(ai.prompt['lengthChars'], 800);
      expect(ai.prompt['note'], '仕事の話を中心に');
      expect(ai.prompt['diaryCount'], 2);
      // 日付の古い順
      expect(
        ai.prompt['diariesText'],
        '■2026年1月1日 t1\nc1\n\n■2026年1月2日 t2\nc2',
      );
      expect(ai.prompt['diariesChars'], '2026年1月1日 t1\nc1\n\n2026年1月2日 t2\nc2'.length);
    });
  });

  group('書き方の相談', () {
    test('最初は、日記の全文(「■」なし)と件数を送る', () async {
      final ai = CapturingAi();
      await ConsultSummaryUseCase(aiRepository: ai).start(
        diaries: [diary(2, 't2', 'c2'), diary(1, 't1', 'c1')],
      );

      expect(ai.prompt, {
        'kind': 'consult_first',
        'diaryCount': 2,
        'diariesText': '2026年1月1日 t1\nc1\n\n2026年1月2日 t2\nc2',
      });
    });

    test('続きは、材料メモと会話だけを送る(日記の全文は送らない)', () async {
      final ai = CapturingAi();
      await ConsultSummaryUseCase(aiRepository: ai).followUp(
        brief: 'MEMO',
        history: const [
          ConsultMessage(fromUser: true, text: '章立てにしたい'),
          ConsultMessage(fromUser: false, text: 'こうします', proposal: '仕事の章に'),
          ConsultMessage(fromUser: false, text: '質問ですか'),
        ],
        message: 'もっと短くして',
      );

      expect(ai.prompt, {
        'kind': 'consult_follow_up',
        'brief': 'MEMO',
        'history': [
          {'fromUser': true, 'text': '章立てにしたい'},
          {'fromUser': false, 'text': 'こうします', 'proposal': '仕事の章に'},
          {'fromUser': false, 'text': '質問ですか'},
        ],
        'message': 'もっと短くして',
      });
    });
  });

  group('AIの回答が空のとき', () {
    for (final answer in ['', '  \n', 'タイトル: 無題\n本文:\n', 'タイトル:\n本文:\n']) {
      test('ふつうの日記: 本文が空なら、失敗にする(${answer.replaceAll('\n', '\\n')})', () async {
        final ai = CapturingAi(answer: answer);
        final day = DateTime(2026, 1, 1);

        await expectLater(
          GenerateDiaryUseCase(aiRepository: ai, photoRepository: NoPhotos())
              .execute(
                note: '',
                diaryDate: day,
                startDate: day,
                endDate: day,
                photos: const <Photo>[],
                timeline: const [],
                posts: const [],
              ),
          throwsA(isA<AiEmptyDiaryException>()),
        );
      });

      test('日記を1つにする: 本文が空なら、失敗にする(${answer.replaceAll('\n', '\\n')})', () async {
        final ai = CapturingAi(answer: answer);

        await expectLater(
          GenerateSummaryDiaryUseCase(aiRepository: ai).execute(
            note: '',
            diaries: [diary(1, 't1', 'c1'), diary(2, 't2', 'c2')],
          ),
          throwsA(isA<AiEmptyDiaryException>()),
        );
      });
    }

    test('タイトルがなくても、本文があれば、失敗にしない', () async {
      final ai = CapturingAi(answer: 'タイトルなしの本文');
      final day = DateTime(2026, 1, 1);

      final result = await GenerateDiaryUseCase(
        aiRepository: ai,
        photoRepository: NoPhotos(),
      ).execute(
        note: '',
        diaryDate: day,
        startDate: day,
        endDate: day,
        photos: const <Photo>[],
        timeline: const [],
        posts: const [],
      );

      expect(result.title, '');
      expect(result.content, 'タイトルなしの本文');
    });

    test('使用量は、失敗にも付いてくる(画面に反映するため)', () {
      const usage = UsageInfo(usedTokens: 10, limitTokens: 100);

      expect(AiEmptyDiaryException(usage).usage, usage);
    });
  });
}
