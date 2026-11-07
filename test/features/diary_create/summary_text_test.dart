import 'package:auto_diary_ai/features/diary/domain/entities/diary.dart';
import 'package:auto_diary_ai/features/diary_create/domain/services/summary_text.dart';
import 'package:auto_diary_ai/features/diary_create/domain/services/token_estimator.dart';
import 'package:flutter_test/flutter_test.dart';

Diary diary(int month, int day, String title, String content) => Diary(
  date: DateTime(2026, month, day),
  title: title,
  content: content,
  isAiGenerated: false,
  createdAt: DateTime(2026, month, day, 21),
);

void main() {
  group('SummaryText', () {
    test('AIに渡す形は、日記ごとに「■」で区切る', () {
      final text = SummaryText.formatForAi([
        diary(2, 3, '二つ目', '本文2'),
        diary(1, 5, '一つ目', '本文1'),
      ]);

      expect(text, '■2026年1月5日 一つ目\n本文1\n\n■2026年2月3日 二つ目\n本文2');
    });

    test('日付の古い順に、日付・タイトル・本文を並べる', () {
      final text = SummaryText.format([
        diary(2, 3, '二つ目', '本文2'),
        diary(1, 5, '一つ目', '本文1'),
      ]);

      expect(text, '2026年1月5日 一つ目\n本文1\n\n2026年2月3日 二つ目\n本文2');
    });

    test('タイトルがない日記は、日付だけを見出しにする', () {
      expect(SummaryText.format([diary(1, 1, '', '本文')]), '2026年1月1日\n本文');
    });

    test('長さの目安は日記の量の10〜15%で、下限と上限がある', () {
      expect(SummaryText.lengthGuide(15856), '1600〜2400文字');
      expect(SummaryText.lengthGuide(1000), '300〜500文字');
      expect(SummaryText.lengthGuide(500000), '6000〜8000文字');
      // 範囲は、数字でも取り出せる
      final range = SummaryText.lengthRange(1000);
      expect((range.low, range.high), (300, 500));
    });

    test('365件×500文字は、上限に収まる', () {
      final diaries = [
        for (var i = 0; i < 365; i++)
          Diary(
            date: DateTime(2026, 1, 1).add(Duration(days: i)),
            title: 'タイトル',
            content: 'あ' * 500,
            isAiGenerated: true,
            createdAt: DateTime(2026, 1, 1),
          ),
      ];

      expect(SummaryText.length(diaries), lessThan(SummaryText.maxChars));
    });
  });

  group('TokenEstimator(まとめ日記)', () {
    int estimate(List<Diary> diaries) => TokenEstimator.estimate(
      note: '',
      timeline: const [],
      posts: const [],
      photoCount: 0,
      diaries: diaries,
    );

    test('日記の文字数に応じて増える', () {
      final one = estimate([diary(1, 1, 't', 'あ' * 500)]);
      final two = estimate([
        diary(1, 1, 't', 'あ' * 500),
        diary(1, 2, 't', 'あ' * 500),
      ]);

      expect(two, greaterThan(one + 200));
      expect(one, greaterThan(estimate(const [])));
    });
  });
}
