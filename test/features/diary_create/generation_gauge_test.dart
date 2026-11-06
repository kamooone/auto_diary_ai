import 'package:auto_diary_ai/features/ai/domain/entities/ai_model.dart';
import 'package:auto_diary_ai/features/diary/domain/entities/diary.dart';
import 'package:auto_diary_ai/features/diary_create/domain/entities/summary_style.dart';
import 'package:auto_diary_ai/features/diary_create/domain/services/generation_gauge.dart';
import 'package:auto_diary_ai/features/diary_create/domain/services/summary_text.dart';
import 'package:auto_diary_ai/features/diary_create/domain/services/token_estimator.dart';
import 'package:auto_diary_ai/features/diary_create/presentation/ui/widgets/generation_progress.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

List<Diary> diaries(int count, {int chars = 300}) => [
  for (var i = 0; i < count; i++)
    Diary(
      date: DateTime(2026, 1, 1).add(Duration(days: i)),
      title: 't',
      content: 'あ' * chars,
      isAiGenerated: false,
      createdAt: DateTime(2026, 1, 1),
    ),
];

void main() {
  group('GenerationGauge', () {
    test('始めは0で、見積もった時間の90%まで、まっすぐ進む', () {
      expect(GenerationGauge.fraction(0, 20), 0);
      expect(GenerationGauge.fraction(10, 20), closeTo(0.45, 1e-9));
      expect(GenerationGauge.fraction(20, 20), closeTo(0.9, 1e-9));
    });

    test('見積もった時間を過ぎても、100%にはならず、だんだんゆっくり進む', () {
      final a = GenerationGauge.fraction(25, 20);
      final b = GenerationGauge.fraction(60, 20);
      final c = GenerationGauge.fraction(1000, 20);

      expect(a, greaterThan(0.9));
      expect(b, greaterThan(a));
      expect(c, lessThan(1));
      expect(c, closeTo(0.99, 1e-3));
      // 過ぎた直後のほうが、あとより速く進む
      expect(a - 0.9, greaterThan((b - a) / 7));
    });

    test('見積もりが短すぎても、一瞬では進まない', () {
      expect(GenerationGauge.fraction(1, 0), closeTo(0.18, 1e-9));
      expect(GenerationGauge.fraction(1, 1), closeTo(0.18, 1e-9));
    });

    test('時間が戻っても、マイナスにならない', () {
      expect(GenerationGauge.fraction(-3, 20), 0);
    });

    test('見積もった時間を過ぎたかが分かる', () {
      expect(GenerationGauge.isOverExpected(19, 20), isFalse);
      expect(GenerationGauge.isOverExpected(21, 20), isTrue);
    });
  });

  group('TokenEstimator.estimateSeconds', () {
    int seconds({
      List<Diary> diaries = const [],
      SummaryStyle style = SummaryStyle.reading,
      int photoCount = 0,
      AiModel model = AiModel.gpt,
      int lengthChars = 0,
    }) {
      return TokenEstimator.estimateSeconds(
        note: '',
        timeline: const [],
        posts: const [],
        photoCount: photoCount,
        diaries: diaries,
        summaryStyle: style,
        model: model,
        lengthChars: lengthChars,
      );
    }

    test('日記を連結させるは、AIを使わないので0秒', () {
      expect(seconds(diaries: diaries(10), style: SummaryStyle.chronicle), 0);
    });

    test('GPTの出来事の一覧は、実測(31件で25秒)に近い', () {
      final s = seconds(diaries: diaries(31), style: SummaryStyle.list);

      expect(s, inInclusiveRange(15, 30));
    });

    test('GPTの簡単なブログ風は、読み物より短い', () {
      final brief = seconds(diaries: diaries(31), style: SummaryStyle.brief);
      final reading = seconds(diaries: diaries(31), style: SummaryStyle.reading);

      expect(brief, lessThan(reading));
      expect(brief, inInclusiveRange(5, 15));
    });

    test('件数が多いほど、時間がかかる', () {
      final few = seconds(diaries: diaries(10), style: SummaryStyle.list);
      final many = seconds(diaries: diaries(100), style: SummaryStyle.list);

      expect(many, greaterThan(few));
    });

    test('文字数の目安が大きいほど、時間がかかる', () {
      final short = seconds(lengthChars: 500);
      final long = seconds(lengthChars: 6000);

      expect(long, greaterThan(short));
    });

    test('ふつうのGeminiの日記(写真1枚)は、実測(約3秒)に近い', () {
      final s = seconds(photoCount: 1, model: AiModel.gemini);

      expect(s, inInclusiveRange(3, 6));
    });

    test('Geminiの30件の読み物は、実測(約13秒)に近い', () {
      final s = seconds(
        diaries: diaries(30, chars: 580),
        model: AiModel.gemini,
      );

      expect(s, inInclusiveRange(5, 20));
    });
  });

  group('実測との比較(ゲージが途中で終わらないこと)', () {
    // 日記の合計の文字数が約[chars]になるよう、[count]件の日記を作る
    List<Diary> sized(int count, int totalChars) {
      final one = diaries(1, chars: 100);
      final overhead = SummaryText.length(one) - 100;
      final each = (totalChars / count - overhead).round();

      return diaries(count, chars: each);
    }

    int seconds(List<Diary> d, AiModel model, {SummaryStyle? style}) {
      return TokenEstimator.estimateSeconds(
        note: '',
        timeline: const [],
        posts: const [],
        photoCount: 0,
        diaries: d,
        summaryStyle: style ?? SummaryStyle.reading,
        model: model,
      );
    }

    // [actual]秒で終わったとき、ゲージがどこまで進んでいるか
    double gaugeAtFinish(int estimated, double actual) =>
        GenerationGauge.fraction(actual, estimated);

    test('Gemini 353件(約21.5万文字)は実測31.5秒', () {
      final s = seconds(sized(353, 215000), AiModel.gemini);

      expect(s, inInclusiveRange(25, 45));
      expect(gaugeAtFinish(s, 31.5), greaterThan(0.6));
    });

    test('Gemini 120件(約5万文字)は実測9.8秒', () {
      final s = seconds(sized(120, 50000), AiModel.gemini);

      expect(s, inInclusiveRange(8, 22));
      // 以前は約47秒の見込みで、ゲージが約19%で終わっていた
      expect(gaugeAtFinish(s, 9.8), greaterThan(0.4));
    });

    test('GPT 353件(約22.6万文字)は実測56.4秒', () {
      final s = seconds(sized(353, 226000), AiModel.gpt);

      expect(s, inInclusiveRange(45, 80));
      // 以前は約147秒の見込みで、ゲージが約35%で終わっていた
      expect(gaugeAtFinish(s, 56.4), greaterThan(0.6));
    });

    test('GPT 86件のブログ風(約3.5万文字)は実測32秒', () {
      final s = seconds(sized(86, 35000), AiModel.gpt);

      expect(s, inInclusiveRange(25, 45));
      expect(gaugeAtFinish(s, 32), greaterThan(0.6));
    });

    test('GPT 31件の出来事の一覧は実測25秒(出力が遅い)', () {
      final s = seconds(
        sized(31, 9300),
        AiModel.gpt,
        style: SummaryStyle.list,
      );

      expect(s, inInclusiveRange(18, 32));
    });
  });

  group('GenerationProgress', () {
    testWidgets('作成中は、ゲージとパーセントと、目安であることを示す', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: GenerationProgress(expectedSeconds: 20)),
        ),
      );

      expect(find.text('日記を書いています…'), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
      expect(find.textContaining('目安'), findsOneWidget);
      expect(find.text('0%'), findsOneWidget);

      await tester.pump(const Duration(seconds: 5));

      final bar = tester.widget<LinearProgressIndicator>(
        find.byType(LinearProgressIndicator),
      );
      expect(bar.value, greaterThan(0.1));
      expect(bar.value, lessThan(0.9));
      // 20秒の見積もりの5秒後 = 90% × 5/20 = 22%
      expect(find.text('22%'), findsOneWidget);

      // 画面を閉じたあとに、タイマーが残らないようにする
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('見積もった時間を過ぎたら、もう少しかかることを伝える', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: GenerationProgress(expectedSeconds: 5)),
        ),
      );

      await tester.pump(const Duration(seconds: 8));

      expect(find.textContaining('もう少しかかっています'), findsOneWidget);

      final bar = tester.widget<LinearProgressIndicator>(
        find.byType(LinearProgressIndicator),
      );
      expect(bar.value, lessThan(1));

      await tester.pumpWidget(const SizedBox());
    });
  });
}
