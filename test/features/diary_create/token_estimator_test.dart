import 'package:auto_diary_ai/features/ai/domain/entities/ai_model.dart';
import 'package:auto_diary_ai/features/diary/domain/entities/diary.dart';
import 'package:auto_diary_ai/features/diary_create/domain/entities/summary_style.dart';
import 'package:auto_diary_ai/features/diary_create/domain/services/summary_text.dart';
import 'package:auto_diary_ai/features/diary_create/domain/services/timeline_text.dart';
import 'package:auto_diary_ai/features/diary_create/domain/services/token_estimator.dart';
import 'package:auto_diary_ai/features/diary_create/presentation/ui/widgets/token_shortage_dialog.dart';
import 'package:auto_diary_ai/features/location/domain/entities/timeline_item.dart';
import 'package:auto_diary_ai/features/share/domain/entities/shared_post.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final stay = Stay(
    start: DateTime(2026, 1, 1, 9),
    end: DateTime(2026, 1, 1, 10),
    latitude: 35,
    longitude: 139,
    placeName: '東京駅',
  );

  int estimate({
    String note = '',
    List<TimelineItem> timeline = const [],
    List<SharedPost> posts = const [],
    int photoCount = 0,
    double multiplier = 1,
  }) {
    return TokenEstimator.estimate(
      note: note,
      timeline: timeline,
      posts: posts,
      photoCount: photoCount,
      multiplier: multiplier,
    );
  }

  group('TokenEstimator', () {
    test('何も選ばなくても、指示文と出力の分はかかる', () {
      expect(
        estimate(),
        TokenEstimator.instructionTokens + TokenEstimator.outputTokens,
      );
    });

    test('写真が増えると、1枚ぶんずつ増える', () {
      expect(
        estimate(photoCount: 3) - estimate(),
        3 * TokenEstimator.tokensPerPhoto,
      );
    });

    test('メモ・行動履歴・投稿の文字数が増えると増える', () {
      final base = estimate();

      expect(estimate(note: 'あ' * 100), greaterThan(base + 40));
      expect(estimate(timeline: [stay]), greaterThan(base));
      expect(
        estimate(
          posts: [
            SharedPost(
              url: 'https://x.com/a/1',
              text: 'こんにちは',
              receivedAt: DateTime(2026, 1, 1),
            ),
          ],
        ),
        greaterThan(base),
      );
    });

    test('行動履歴は、AIに渡す文章と同じものの長さで数える', () {
      final length = TimelineText.format([stay]).length;

      expect(
        estimate(timeline: [stay]) - estimate(),
        (length * TokenEstimator.tokensPerChar).ceil(),
      );
    });

    test('AIの種類による倍率を掛ける', () {
      expect(estimate(multiplier: 2), estimate() * 2);
    });
  });

  // GPT(gpt-5-mini)の実測(2026-11-04)。見積もりは、実際より少なく、実測の8割以上にする
  group('TokenEstimator(文字数の目安)', () {
    int withLength(AiModel model, int chars) => TokenEstimator.estimate(
      note: '',
      timeline: const [],
      posts: const [],
      photoCount: 0,
      model: model,
      lengthChars: chars,
    );

    test('指定しないときは、これまでと同じ', () {
      expect(
        withLength(AiModel.gpt, 0),
        TokenEstimator.estimate(
          note: '',
          timeline: const [],
          posts: const [],
          photoCount: 0,
          model: AiModel.gpt,
        ),
      );
    });

    test('文字数が多いほど、出力の見積もりが増える', () {
      expect(
        withLength(AiModel.gpt, 3000),
        greaterThan(withLength(AiModel.gpt, 1000)),
      );
      expect(
        withLength(AiModel.gemini, 3000),
        greaterThan(withLength(AiModel.gemini, 1000)),
      );
    });

    test('短い目安(200文字)では、これまでの出力の見積もりを下回らない', () {
      expect(
        withLength(AiModel.gpt, 200),
        greaterThanOrEqualTo(withLength(AiModel.gpt, 0)),
      );
      expect(
        withLength(AiModel.gemini, 200),
        greaterThanOrEqualTo(withLength(AiModel.gemini, 0)),
      );
    });
  });

  group('TokenEstimator(GPT・ふつうの日記)', () {
    int plain(int photos) => TokenEstimator.estimate(
      note: '',
      timeline: const [],
      posts: const [],
      photoCount: photos,
      model: AiModel.gpt,
    );

    // 実測(2026-11-05): 写真1枚 1,077、3枚 2,103。見積もりは実測の80%以上100%未満
    test('写真1枚は、実測1,077の80〜100%', () {
      expect(plain(1), inInclusiveRange(862, 1076));
    });

    test('写真3枚は、実測2,103の80〜100%', () {
      expect(plain(3), inInclusiveRange(1683, 2102));
    });

    test('写真1枚あたりは、Geminiより少ない', () {
      expect(
        TokenEstimator.photoTokens(AiModel.gpt),
        lessThan(TokenEstimator.photoTokens(AiModel.gemini)),
      );
    });
  });

  group('TokenEstimator(GPT)', () {
    // 日記の文字数(SummaryText.length)が[chars]になる、[count]件の日記
    List<Diary> diaries(int count, int chars) {
      List<Diary> build(int lastLength) => [
        for (var i = 0; i < count; i++)
          Diary(
            date: DateTime(2026, 1, 1 + i),
            title: 't',
            content: 'あ' * (i == count - 1 ? lastLength : 100),
            isAiGenerated: false,
            createdAt: DateTime(2026, 1, 1 + i, 21),
          ),
      ];

      var last = 100;
      while (SummaryText.length(build(last)) < chars) {
        last++;
      }
      return build(last);
    }

    int estimate(List<Diary> d, SummaryStyle style, AiModel model) =>
        TokenEstimator.estimate(
          note: '',
          timeline: const [],
          posts: const [],
          photoCount: 0,
          diaries: d,
          summaryStyle: style,
          model: model,
        );

    void expectBetween(int actual, int estimated) {
      expect(estimated, lessThanOrEqualTo(actual));
      expect(estimated, greaterThanOrEqualTo((actual * 0.8).floor()));
    }

    test('3件・出来事の一覧(実測1,879)', () {
      expectBetween(
        1879,
        estimate(diaries(3, 1256), SummaryStyle.list, AiModel.gpt),
      );
    });

    test('31件・出来事の一覧(実測13,111)', () {
      expectBetween(
        13111,
        estimate(diaries(31, 13212), SummaryStyle.list, AiModel.gpt),
      );
    });

    test('31件・簡単なブログ風(実測12,660)', () {
      expectBetween(
        12660,
        estimate(diaries(31, 13212), SummaryStyle.brief, AiModel.gpt),
      );
    });

    test('31件・ブログ風(実測14,617)', () {
      expectBetween(
        14617,
        estimate(diaries(31, 13212), SummaryStyle.reading, AiModel.gpt),
      );
    });

    test('31件・相談(実測12,932)', () {
      expectBetween(
        12932,
        TokenEstimator.estimateConsult(
          diaries(31, 13212),
          model: AiModel.gpt,
        ),
      );
    });

    test('Geminiの見積もりは、これまでと同じ', () {
      final d = diaries(31, 13212);

      expect(estimate(d, SummaryStyle.list, AiModel.gemini), 7271);
      expect(estimate(d, SummaryStyle.reading, AiModel.gemini), 7863);
    });
  });

  group('不足を知らせるダイアログ', () {
    Future<TokenShortageChoice?> open(
      WidgetTester tester,
      String buttonLabel,
    ) async {
      TokenShortageChoice? result;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => TextButton(
              onPressed: () async {
                result = await showTokenShortageDialog(
                  context,
                  estimated: 9000,
                  remaining: 1200,
                  photoTokens: 1050,
                );
              },
              child: const Text('開く'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('開く'));
      await tester.pumpAndSettle();

      expect(find.textContaining('約9,000'), findsOneWidget);
      expect(find.textContaining('1,200'), findsOneWidget);

      await tester.tap(find.text(buttonLabel));
      await tester.pumpAndSettle();

      return result;
    }

    testWidgets('「それでも送る」を選べる', (tester) async {
      expect(await open(tester, 'それでも送る'), TokenShortageChoice.sendAnyway);
    });

    testWidgets('「やめる」を選べる', (tester) async {
      expect(await open(tester, 'やめる'), TokenShortageChoice.cancel);
    });

    testWidgets('「ポイント・トークンを見る」を選べる', (tester) async {
      expect(
        await open(tester, 'ポイント・トークンを見る'),
        TokenShortageChoice.openPoints,
      );
    });
  });
}
