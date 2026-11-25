import 'package:auto_diary_ai/features/ai/domain/entities/ai_model.dart';
import 'package:auto_diary_ai/features/diary/domain/entities/diary.dart';
import 'package:auto_diary_ai/features/diary_create/domain/entities/diary_length.dart';
import 'package:auto_diary_ai/features/diary_create/domain/entities/photo.dart';
import 'package:auto_diary_ai/features/diary_create/domain/entities/summary_style.dart';
import 'package:auto_diary_ai/features/diary_create/domain/services/summary_text.dart';
import 'package:auto_diary_ai/features/diary_create/domain/services/timeline_text.dart';
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

    test('ひとことメモは、AIに渡す文章と同じものの長さで数える', () {
      final memos = [
        Memo(text: 'カフェでのんびり', createdAt: DateTime(2026, 11, 9, 12, 34)),
      ];
      final length = MemoText.format(memos).length;

      expect(
        estimate(memos: memos) - estimate(),
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

  group('TokenEstimator(GPT・ふつうの日記)', () {
    Photo photo(int w, int h) =>
        Photo(id: '$w$h', createdAt: DateTime(2026, 1, 1), width: w, height: h);

    int plain(List<Photo> photos) => TokenEstimator.estimate(
      note: '',
      timeline: const [],
      posts: const [],
      photoCount: photos.length,
      photos: photos,
      model: AiModel.gpt,
    );

    // 実測(2026-11-11、長辺1024に縮小): 写真1枚(縦長) 1,599、3枚(縦長) 3,126、
    // 10枚(縦長6枚+横長4枚) 8,064。縦横は、撮った大きさ(縮小前)で渡す。
    // 見積もりは、実測の80%以上100%未満
    test('写真1枚は、実測1,599の80〜100%', () {
      expect(plain([photo(1080, 1920)]), inInclusiveRange(1280, 1598));
    });

    test('写真3枚は、実測3,126の80〜100%', () {
      expect(
        plain([for (var i = 0; i < 3; i++) photo(1080, 1920)]),
        inInclusiveRange(2501, 3125),
      );
    });

    test('写真10枚(縦長6+横長4)は、実測8,064の80〜100%', () {
      expect(
        plain([
          for (var i = 0; i < 6; i++) photo(1080, 1920),
          for (var i = 0; i < 4; i++) photo(1920, 1080),
        ]),
        inInclusiveRange(6452, 8063),
      );
    });

    test('写真100枚でも、実測から計算した実際(約70,300)を超えない', () {
      // 写真1枚あたりの入力は実測で約692。写真以外の入力約600+出力約600を足す
      final est = plain([for (var i = 0; i < 100; i++) photo(1080, 1920)]);
      expect(est, inInclusiveRange(70300 * 0.8, 70300));
    });

    test('縦長と横長は、同じトークンになる', () {
      expect(plain([photo(1080, 1920)]), plain([photo(1920, 1080)]));
    });

    test('4:3や正方形の写真は、16:9より多くなる', () {
      final wide = plain([photo(1920, 1080)]);
      expect(plain([photo(4000, 3000)]), greaterThan(wide));
      expect(
        plain([photo(3000, 3000)]),
        greaterThan(plain([photo(4000, 3000)])),
      );
    });

    test('小さい写真は、拡大せずに計算する', () {
      expect(plain([photo(320, 320)]), lessThan(plain([photo(1920, 1080)])));
    });

    test('縦横が分からない写真は、16:9として計算する', () {
      expect(
        plain([Photo(id: 'x', createdAt: DateTime(2026, 1, 1))]),
        plain([photo(1920, 1080)]),
      );
    });

    test('Geminiは、縦横に関係なく1枚あたり一定', () {
      int gemini(Photo p) => TokenEstimator.estimate(
        note: '',
        timeline: const [],
        posts: const [],
        photoCount: 1,
        photos: [p],
        model: AiModel.gemini,
      );
      expect(gemini(photo(3000, 3000)), gemini(photo(1920, 1080)));
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
        TokenEstimator.estimateConsult(diaries(31, 13212), model: AiModel.gpt),
      );
    });

    test('Geminiの日記を1つにする見積もりは、指示文の分(+70)だけ増えた', () {
      // 2026-11-25: Geminiの指示文を200→270にした(実測の入力が約340になったため)。
      // 日記1文字あたりの係数は変えていないので、増えたのは指示文の分だけ
      final d = diaries(31, 13212);

      expect(estimate(d, SummaryStyle.list, AiModel.gemini), 7271 + 70);
      expect(estimate(d, SummaryStyle.reading, AiModel.gemini), 7863 + 70);
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
