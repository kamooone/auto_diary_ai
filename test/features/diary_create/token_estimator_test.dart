import 'package:auto_diary_ai/features/ai/domain/entities/ai_model.dart';
import 'package:auto_diary_ai/features/diary/domain/entities/diary.dart';
import 'package:auto_diary_ai/features/diary_create/domain/entities/diary_length.dart';
import 'package:auto_diary_ai/features/diary_create/domain/entities/summary_style.dart';
import 'package:auto_diary_ai/features/diary_create/domain/services/timeline_text.dart';
import 'package:auto_diary_ai/features/diary_create/domain/services/summary_text.dart';
import 'package:auto_diary_ai/features/diary_create/domain/services/token_estimator.dart';
import 'package:auto_diary_ai/features/diary_create/presentation/ui/widgets/token_shortage_dialog.dart';
import 'package:auto_diary_ai/features/location/domain/entities/timeline_item.dart';
import 'package:auto_diary_ai/features/memo/domain/entities/memo.dart';
import 'package:auto_diary_ai/features/memo/domain/services/memo_text.dart';
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
    List<Memo> memos = const [],
    int photoCount = 0,
    double multiplier = 1,
  }) {
    return TokenEstimator.estimate(
      note: note,
      timeline: timeline,
      posts: posts,
      memos: memos,
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

    // 2026-11-25の実測(Gemini 3.5 Flash Lite、メモ欄だけ)。見積もりは、実測の60〜100%に収める
    group('メモ(Gemini)の見積もりは、実測の60〜100%', () {
      void expectRate(int actual, int estimated) {
        expect(estimated, lessThanOrEqualTo(actual));
        expect(estimated, greaterThanOrEqualTo((actual * 0.6).ceil()));
      }

      test('何も選ばない(実測389)', () {
        expectRate(389, estimate());
      });

      test('メモ969文字(実測1,475)', () {
        expectRate(1475, estimate(note: 'あ' * 969));
      });

      test('メモ9,366文字(実測5,967)', () {
        expectRate(5967, estimate(note: 'あ' * 9366));
      });

      test('量が変わっても、見積もり÷実測は、約70〜90%でそろう(A1〜A6の実測)', () {
        final cases = <(int, int)>[
          (389, estimate()),
          (1475, estimate(note: 'あ' * 969)),
          (5967, estimate(note: 'あ' * 9366)),
          (1494, estimate(photoCount: 1)),
          (3966, estimate(photoCount: 3)),
          (12011, estimate(photoCount: 10)),
        ];

        for (final (actual, estimated) in cases) {
          final rate = estimated / actual;
          expect(
            rate,
            inInclusiveRange(0.7, 0.9),
            reason: '実測$actual 見積もり$estimated',
          );
        }
      });

      test('メモが長くても、出力の増え方には上限がある', () {
        final small = estimate(note: 'あ' * 1000);
        final large = estimate(note: 'あ' * 2000);

        // 増えるのは、入力の分(1文字0.52)だけで、出力は、上限(300)で増えない
        expect(
          large - small,
          (1000 * TokenEstimator.noteTokensPerChar).round(),
        );
      });
    });

    test('写真が増えると、1枚ぶんずつ増える', () {
      expect(
        estimate(photoCount: 3) - estimate(),
        3 * (TokenEstimator.tokensPerPhoto + TokenEstimator.photoTimeTokens),
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
        TokenEstimator.timelineTokens(length).ceil(),
      );
    });

    // 2026-11-25の最終テスト(Gemini)。履歴だけを選んだときの、履歴の入力トークン(実測)。
    // 「一定の分 + 文字数に比例する分」の式(250 + 0.66 × 文字数)。約266文字未満は、1文字あたり1.6が上限
    group('行動履歴の見積もり(Gemini)は、実測の約80%', () {
      void expectRate(int chars, int actual) {
        final rate = TokenEstimator.timelineTokens(chars) / actual;
        expect(rate, inInclusiveRange(0.75, 0.9), reason: '$chars文字・実測$actual');
      }

      test('10件(約270文字)・実測540', () => expectRate(270, 540));
      test('10件・6日分(約314文字)・実測585', () => expectRate(314, 585));
      test('10件・住所つき(約348文字)・実測614', () => expectRate(348, 614));
      test('100件(約3,043文字)・実測2,829', () => expectRate(3043, 2829));
      test('500件(約15,100文字)・実測12,804', () => expectRate(15100, 12804));

      test('文字数が増えるほど、1文字あたりは減る', () {
        double perChar(int chars) =>
            TokenEstimator.timelineTokens(chars) / chars;

        expect(perChar(100), greaterThanOrEqualTo(perChar(300)));
        expect(perChar(300), greaterThan(perChar(3000)));
        expect(perChar(3000), greaterThan(perChar(30000)));
      });

      test('文字数が少ないとき(1件)は、1文字あたり1.6を超えない', () {
        expect(
          TokenEstimator.timelineTokens(30),
          lessThanOrEqualTo(30 * TokenEstimator.timelineTokensPerChar),
        );
      });

      test('履歴がなければ、0', () {
        expect(TokenEstimator.timelineTokens(0), 0);
      });
    });

    // 2026-11-25の最終テスト(Gemini)。Xの投稿だけを選んだときの、投稿の入力トークン(実測)
    group('Xの投稿の見積もり(Gemini)は、実測の約80%', () {
      void expectRate(int chars, int actual) {
        final rate = TokenEstimator.postsTokens(chars) / actual;
        expect(rate, inInclusiveRange(0.75, 0.9), reason: '$chars文字・実測$actual');
      }

      test('10件(約1,204文字)・実測1,190', () => expectRate(1204, 1190));
      test('50件(約6,164文字)・実測4,750', () => expectRate(6164, 4750));

      test('文字数が増えるほど、1文字あたりは減る', () {
        double perChar(int chars) => TokenEstimator.postsTokens(chars) / chars;

        expect(perChar(100), greaterThanOrEqualTo(perChar(1000)));
        expect(perChar(1000), greaterThan(perChar(10000)));
      });

      test('投稿がなければ、0', () {
        expect(TokenEstimator.postsTokens(0), 0);
      });
    });

    test('ひとことメモは、AIに渡す文章と同じものの長さで数える', () {
      final memos = [
        Memo(text: 'カフェでのんびり', createdAt: DateTime(2026, 11, 9, 12, 34)),
      ];
      final length = MemoText.format(memos).length;

      expect(
        estimate(memos: memos) - estimate(),
        TokenEstimator.postsTokens(length).ceil(),
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

  group('文字数の目安の入力', () {
    test('空・数字でない・0は、指定しない(0)', () {
      expect(DiaryLength.parse(''), 0);
      expect(DiaryLength.parse('abc'), 0);
      expect(DiaryLength.parse('0'), 0);
    });

    test('数字は、そのまま文字数になる', () {
      expect(DiaryLength.parse('800'), 800);
      expect(DiaryLength.parse(' 1500 '), 1500);
    });

    test('文字数に上限はなく、大きな数もそのまま文字数になる', () {
      expect(DiaryLength.parse('3001'), 3001);
      expect(DiaryLength.parse('100000'), 100000);
    });
  });

  group('TokenEstimator(まとめ日記の文字数の目安)', () {
    final diaries = [
      Diary(
        date: DateTime(2026, 1, 1),
        title: 'あ',
        content: 'あ' * 5000,
        isAiGenerated: false,
        createdAt: DateTime(2026, 1, 1),
      ),
      Diary(
        date: DateTime(2026, 1, 2),
        title: 'い',
        content: 'い' * 5000,
        isAiGenerated: false,
        createdAt: DateTime(2026, 1, 2),
      ),
    ];

    int output(SummaryStyle style, int chars) =>
        TokenEstimator.summaryOutputTokens(
          style,
          diaries,
          model: AiModel.gpt,
          lengthChars: chars,
        );

    test('目安を指定すると、日記の量ではなく、その長さで出力を見積もる', () {
      expect(output(SummaryStyle.reading, 800), 400);
      expect(output(SummaryStyle.brief, 800), 400);
      expect(output(SummaryStyle.custom, 800), 400);
    });

    test('指定しないときは、これまでと同じ', () {
      expect(
        output(SummaryStyle.reading, 0),
        TokenEstimator.summaryOutputTokens(
          SummaryStyle.reading,
          diaries,
          model: AiModel.gpt,
        ),
      );
    });

    test('出来事の一覧と、日記を連結させるは、目安の影響を受けない', () {
      expect(
        output(SummaryStyle.list, 800),
        TokenEstimator.summaryOutputTokens(
          SummaryStyle.list,
          diaries,
          model: AiModel.gpt,
        ),
      );
      expect(output(SummaryStyle.chronicle, 800), 0);
    });
  });

  // GPTは、Geminiの係数に、材料ごとの倍率をかけた値(2026-11-26、ユーザー指示)。GPTのテストをして、微調整する。
  //  文字(指示文・メモ)は×1.3、写真は×0.6(GPTは写真が少ない)、履歴・投稿はGeminiと同じ、考える分は+100(考える量 low)
  group('TokenEstimator(GPTは、Geminiに、材料ごとの倍率をかけたもの)', () {
    int tokens(
      AiModel model, {
      String note = '',
      int photoCount = 0,
      List<TimelineItem> timeline = const [],
      List<SharedPost> posts = const [],
    }) => TokenEstimator.estimate(
      note: note,
      timeline: timeline,
      posts: posts,
      photoCount: photoCount,
      model: model,
    );

    // 実測(2026-11-26。考える量 low): 何も選ばない640、メモ969文字2,044、写真3枚3,056
    test('何も選ばない・メモだけ・写真だけは、実測(思考を含む)の約70〜90%で、超えない', () {
      expect(tokens(AiModel.gpt) / 640, inInclusiveRange(0.7, 0.9));
      expect(
        tokens(AiModel.gpt, note: 'あ' * 969) / 2044,
        inInclusiveRange(0.65, 0.9),
      );
      expect(
        tokens(AiModel.gpt, photoCount: 3) / 3056,
        inInclusiveRange(0.65, 0.9),
      );
    });

    test('入力の見積もりだけでは、実測の入力を超えない(指示文417・メモ969文字で1,222)', () {
      // 考える分と、出力を除いた、入力だけの見積もり
      final instruction = tokens(AiModel.gpt) - 40 - 100;
      final withNote = tokens(AiModel.gpt, note: 'あ' * 969) - 40 - 350 - 100;

      expect(instruction, lessThan(417));
      expect(withNote, lessThan(1222));
    });

    test('写真1枚は、Geminiより少なく、実測(約690+撮影日時約28)を超えない', () {
      final one =
          TokenEstimator.photoTokens(AiModel.gpt) +
          TokenEstimator.photoTimeTokens;

      expect(one, lessThan(TokenEstimator.photoTokens(AiModel.gemini)));
      expect(one, lessThanOrEqualTo(690 + 28));
      expect(one / (690 + 28), greaterThanOrEqualTo(0.7));
    });

    test('行動履歴は、Geminiと同じ', () {
      final stay = Stay(
        start: DateTime(2026, 1, 1, 9),
        end: DateTime(2026, 1, 1, 10),
        latitude: 35,
        longitude: 139,
        placeName: '東京駅',
      );

      int added(AiModel model) =>
          tokens(model, timeline: [stay]) - tokens(model);

      expect(added(AiModel.gpt), added(AiModel.gemini));
    });

    // 実測(2026-11-26のG5。考える量 low): 入力から指示文417を除いた、投稿の分。
    // 10件893(約900文字)、100件6,259(約10,200文字)、300件19,149(約34,200文字)。文字数は逆算
    test('Xの投稿は、件数が増えても、実測の約80%(上がり続けない)', () {
      for (final (chars, actual) in [
        (904, 893),
        (10228, 6259),
        (34198, 19149),
      ]) {
        final rate =
            TokenEstimator.postsTokens(chars, model: AiModel.gpt) / actual;

        expect(rate, inInclusiveRange(0.75, 0.86), reason: '$chars文字');
      }
    });

    test('Xの投稿は、文字数が多いほど割合が上がらない(500件・1,000件でも約80%)', () {
      // 傾きが実測(0.538)の約80%なので、多くなっても、80%に近づく
      for (final chars in [57000, 114000]) {
        final actual = 756 + 0.538 * chars;
        final rate =
            TokenEstimator.postsTokens(chars, model: AiModel.gpt) / actual;

        expect(rate, inInclusiveRange(0.78, 0.86), reason: '$chars文字');
      }
    });

    test('Geminiは、これまでどおり(考える分を足さない)', () {
      expect(
        tokens(AiModel.gemini),
        TokenEstimator.instructionTokens + TokenEstimator.outputTokens,
      );
    });
  });

  // 2026-11-25の最終テスト(Gemini)。日記5件(簡単なブログ風)と、25件(ブログ風)。
  // 入力+出力の実測に対して、見積もりが、約70〜90%になる(思考は含めない)
  group('日記を1つにする見積もり(Gemini)は、実測の約80%', () {
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

    int estimate(List<Diary> d, SummaryStyle style) => TokenEstimator.estimate(
      note: '',
      timeline: const [],
      posts: const [],
      photoCount: 0,
      diaries: d,
      summaryStyle: style,
    );

    void expectRate(
      int count,
      int chars,
      SummaryStyle style,
      int actualInputPlusOutput,
    ) {
      final rate =
          estimate(diaries(count, chars), style) / actualInputPlusOutput;
      expect(rate, inInclusiveRange(0.7, 0.9), reason: '$count件・$chars文字');
    }

    test('5件・簡単なブログ風(入力2,240+出力272)', () {
      expectRate(5, 2579, SummaryStyle.brief, 2512);
    });

    test('25件・ブログ風(入力7,335+出力1,049)', () {
      expectRate(25, 9140, SummaryStyle.reading, 8384);
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

    testWidgets('「それでも送る」はない。待つか、ポイントを貯めるよう伝える', (tester) async {
      await open(tester, 'やめる');

      // ダイアログは閉じたので、中身は、開き直して確かめる
      await tester.tap(find.text('開く'));
      await tester.pumpAndSettle();

      expect(find.text('それでも送る'), findsNothing);
      expect(find.textContaining('来月の1日に戻ります'), findsOneWidget);
      expect(find.textContaining('ゲームでポイントを貯めて'), findsOneWidget);
      expect(find.textContaining('書いたあとに'), findsNothing);
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
