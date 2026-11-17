import 'package:auto_diary_ai/features/x_archive/application/providers/x_archive_recall_providers.dart';
import 'package:auto_diary_ai/features/x_archive/domain/entities/x_archive_post.dart';
import 'package:auto_diary_ai/features/x_archive/domain/entities/x_archive_recall.dart';
import 'package:auto_diary_ai/features/x_archive/presentation/ui/x_archive_post_formatter.dart';
import 'package:auto_diary_ai/features/x_archive/presentation/ui/x_archive_recall_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

// 日本時間の [y]年[m]月[d]日 [h]時[min]分 の投稿(保存はUTC)
XArchivePost post(
  String id,
  int y,
  int m,
  int d, {
  int h = 12,
  int min = 0,
  XArchivePostKind kind = XArchivePostKind.post,
  String text = '投稿の本文',
}) {
  return XArchivePost(
    tweetId: id,
    text: text,
    createdAt: DateTime.utc(y, m, d, h, min).subtract(const Duration(hours: 9)),
    kind: kind,
  );
}

void main() {
  test('時刻と、曜日つきの日付は、日本時間で出す', () {
    final p = post('1', 2024, 9, 11, h: 8, min: 58);
    expect(XArchivePostFormatter.time(p.createdAt), '08:58');
    expect(XArchivePostFormatter.dateWithWeekday(p.createdAt), '2024年9月11日（水）');
  });

  Future<void> open(WidgetTester tester, XArchiveRecall recall) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          xArchiveRecallProvider.overrideWith((ref, date) async => recall),
        ],
        child: const MaterialApp(home: XArchiveRecallPage()),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('N年前の今日と、ランダムな投稿を、見出しつきで出す', (tester) async {
    await open(
      tester,
      XArchiveRecall(
        years: [
          XArchiveRecallYear(
            yearsAgo: 1,
            date: DateTime(2025, 12, 6),
            posts: [post('a', 2025, 12, 7, text: '一年前の投稿')],
          ),
          XArchiveRecallYear(
            yearsAgo: 2,
            date: DateTime(2024, 12, 6),
            posts: [post('b', 2024, 12, 6, text: '二年前の投稿')],
          ),
        ],
        randoms: [
          post(
            'c',
            2024,
            9,
            11,
            h: 8,
            min: 58,
            kind: XArchivePostKind.quote,
            text: 'ランダムな投稿',
          ),
        ],
      ),
    );

    expect(find.text('1年前の今日'), findsOneWidget);
    expect(find.text('2025年12月6日（土）'), findsOneWidget);
    expect(find.text('2年前の今日'), findsOneWidget);
    expect(find.text('一年前の投稿'), findsOneWidget);
    expect(find.text('二年前の投稿'), findsOneWidget);

    expect(find.text('ほかにも、こんなポストが'), findsOneWidget);
    expect(find.text('過去のポストから、ランダムに選んでいます'), findsOneWidget);

    // ランダムな投稿は、日付(曜日つき)を上に、時刻だけを下に出す
    expect(find.text('2024年9月11日（水）'), findsOneWidget);
    expect(find.text('08:58'), findsOneWidget);
    expect(find.text('引用'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('その日の投稿がないときは、案内を出す', (tester) async {
    await open(
      tester,
      XArchiveRecall(randoms: [post('c', 2024, 9, 11, text: 'ランダムな投稿')]),
    );

    expect(find.textContaining('この日と同じ月日のポスト'), findsOneWidget);
    expect(find.text('ランダムな投稿'), findsOneWidget);
  });

  testWidgets('何もないときは、取り込みの案内を出す', (tester) async {
    await open(tester, const XArchiveRecall());

    expect(find.textContaining('紹介できるポスト'), findsOneWidget);
  });
}
