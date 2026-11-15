import 'package:auto_diary_ai/features/x_archive/application/providers/x_archive_providers.dart';
import 'package:auto_diary_ai/features/x_archive/domain/entities/x_archive_post.dart';
import 'package:auto_diary_ai/features/x_archive/presentation/ui/x_archive_post_detail_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_x_archive_repository.dart';

void main() {
  late FakeXArchiveRepository repo;

  XArchivePost post() => XArchivePost(
    tweetId: '1',
    text: '元の本文',
    // 日本時間 2020/01/02 03:04
    createdAt: DateTime.utc(2020, 1, 1, 18, 4),
    kind: XArchivePostKind.post,
  );

  setUp(() => repo = FakeXArchiveRepository([post()]));

  Future<void> open(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [xArchiveRepositoryProvider.overrideWithValue(repo)],
        child: MaterialApp(
          home: Builder(
            builder: (context) => TextButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => XArchivePostDetailPage(post: post()),
                ),
              ),
              child: const Text('開く'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('開く'));
    await tester.pumpAndSettle();
  }

  testWidgets('編集で本文を直して保存すると、詳細の画面に反映される', (tester) async {
    await open(tester);
    expect(find.text('元の本文'), findsOneWidget);

    await tester.tap(find.byTooltip('編集'));
    await tester.pumpAndSettle();

    // 日本時間で表示される
    expect(find.text('2020/01/02'), findsOneWidget);
    expect(find.text('03:04'), findsOneWidget);

    await tester.enterText(find.byType(TextField), '直した本文');
    await tester.pump();
    await tester.tap(find.text('保存する'));
    await tester.pumpAndSettle();

    expect(find.text('直した本文'), findsOneWidget);
    expect(repo.posts.single.text, '直した本文');
    // 日時は変えていないので、そのまま
    expect(repo.posts.single.createdAt, DateTime.utc(2020, 1, 1, 18, 4));
  });

  testWidgets('削除を確認すると、投稿が消えて画面が閉じる', (tester) async {
    await open(tester);

    await tester.tap(find.byTooltip('削除'));
    await tester.pumpAndSettle();
    expect(find.text('この投稿を削除しますか?'), findsOneWidget);

    await tester.tap(find.text('削除'));
    await tester.pumpAndSettle();

    expect(repo.posts, isEmpty);
    expect(find.text('開く'), findsOneWidget);
  });

  testWidgets('削除の確認でやめると、何も消えない', (tester) async {
    await open(tester);

    await tester.tap(find.byTooltip('削除'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('やめる'));
    await tester.pumpAndSettle();

    expect(repo.posts, hasLength(1));
  });
}
