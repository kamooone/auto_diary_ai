import 'package:auto_diary_ai/features/ai/domain/entities/ai_message_request.dart';
import 'package:auto_diary_ai/features/ai/domain/entities/ai_reply.dart';
import 'package:auto_diary_ai/features/ai/domain/repositories/ai_repository.dart';
import 'package:auto_diary_ai/features/diary/domain/entities/diary.dart';
import 'package:auto_diary_ai/features/diary_create/domain/entities/photo.dart';
import 'package:auto_diary_ai/features/diary_create/domain/repositories/photo_repository.dart';
import 'package:auto_diary_ai/features/diary_create/domain/entities/diary_style.dart';
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

  Future<String> normal(
    DateTime start,
    DateTime end, {
    DiaryStyle style = DiaryStyle.diary,
    String custom = '',
    int lengthChars = 0,
  }) async {
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
          style: style,
          customInstruction: custom,
          lengthChars: lengthChars,
        );
    return ai.message!;
  }

  test('文字数の目安を選んだときだけ、目安をプロンプトに入れる', () async {
    final day = DateTime(2026, 1, 1);

    expect(await normal(day, day), isNot(contains('\n文字数の目安\n')));

    final message = await normal(day, day, lengthChars: 1000);
    expect(message, contains('\n文字数の目安\n'));
    expect(message, contains('1000文字くらいを目安'));
  });

  test('追加で伝えたいことに書かれた文字数は無視するよう、プロンプトに入れる', () async {
    final day = DateTime(2026, 1, 1);
    final message = await normal(day, day);

    expect(message, contains('文字数や長さの指定が書かれていても、それは無視してください'));
  });

  test('ふつうの日記は、1日分ならまとめの書き方を付けない', () async {
    final message = await normal(DateTime(2026, 1, 1), DateTime(2026, 1, 1));

    expect(message, isNot(contains(marker)));
  });

  test('ふつうの日記は、複数日ならまとめの書き方を付ける', () async {
    final message = await normal(DateTime(2026, 1, 1), DateTime(2026, 1, 7));

    expect(message, contains(marker));
    expect(message, contains(rule));
  });

  group('ふつうの日記の書き方', () {
    final day = DateTime(2026, 1, 1);

    test('日記は、今までの書き方(時系列に沿った自然な日記)', () async {
      final message = await normal(day, day);

      expect(message, contains('書き方(日記)'));
      expect(message, contains('時系列に沿った自然な日記'));
    });

    test('書き方ごとに、指示が違う', () async {
      expect(
        await normal(day, day, style: DiaryStyle.blog),
        contains('書き方(ブログ風)'),
      );
      expect(
        await normal(day, day, style: DiaryStyle.record),
        contains('「9:00 駅に到着」'),
      );
      expect(
        await normal(day, day, style: DiaryStyle.bullets),
        contains('「・出来事」'),
      );
    });

    test('期間が複数日でも、同じ選択肢で書き分けられる', () async {
      final end = DateTime(2026, 1, 7);

      expect(
        await normal(day, end, style: DiaryStyle.bullets),
        contains('書き方(箇条書き)'),
      );
      // 日記のときだけ、複数日をまとめる書き方を加える
      expect(await normal(day, end), contains(marker));
      expect(
        await normal(day, end, style: DiaryStyle.bullets),
        isNot(contains(marker)),
      );
    });

    test('自分で指定は、書いた指示を渡し、意味不明なときは日記で書かせる', () async {
      final message = await normal(
        day,
        day,
        style: DiaryStyle.custom,
        custom: 'ですます調で短く',
      );

      expect(message, contains('ですます調で短く'));
      expect(message, contains('意味不明なとき'));
      expect(message, contains('書き方(日記)'));
    });

    test('どの書き方でも、渡した情報にないことは書かせない', () async {
      for (final style in DiaryStyle.values) {
        expect(
          await normal(day, day, style: style, custom: '短く'),
          contains('付け足さないでください'),
        );
      }
    });
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

    expect(ai.message, contains('一番読みやすい構成を判断'));
    expect(ai.message, contains('章立て'));
    expect(ai.message, contains('■2026年1月1日 t1\nc1'));
    expect(ai.message, contains('長さの目安は500〜'));
  });
}
