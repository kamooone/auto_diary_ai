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

      expect(estimate(note: 'あ' * 100), greaterThan(base + 99));
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
