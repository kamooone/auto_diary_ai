import 'package:auto_diary_ai/features/x_archive/application/services/x_archive_recall_builder.dart';
import 'package:auto_diary_ai/features/x_archive/domain/entities/x_archive_post.dart';
import 'package:auto_diary_ai/features/x_archive/domain/services/x_archive_recall_rules.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_x_archive_repository.dart';

// 日本時間の [y]年[m]月[d]日 [h]時 の投稿(保存はUTC)
XArchivePost post(
  String id,
  int y,
  int m,
  int d, {
  int h = 12,
  XArchivePostKind kind = XArchivePostKind.post,
  String text = 'これは十分に長い投稿の本文です',
}) {
  return XArchivePost(
    tweetId: id,
    text: text,
    createdAt: DateTime.utc(y, m, d, h).subtract(const Duration(hours: 9)),
    kind: kind,
  );
}

void main() {
  final today = DateTime(2026, 11, 11);

  test('投稿の対象:通常と引用だけ。短い投稿は除く', () {
    expect(isXArchiveRecallEligible(post('1', 2025, 1, 1)), isTrue);
    expect(
      isXArchiveRecallEligible(
        post('1', 2025, 1, 1, kind: XArchivePostKind.quote),
      ),
      isTrue,
    );
    expect(
      isXArchiveRecallEligible(
        post('1', 2025, 1, 1, kind: XArchivePostKind.reply),
      ),
      isFalse,
    );
    expect(
      isXArchiveRecallEligible(
        post('1', 2025, 1, 1, kind: XArchivePostKind.retweet),
      ),
      isFalse,
    );
    expect(
      isXArchiveRecallEligible(post('1', 2025, 1, 1, text: 'おはよう')),
      isFalse,
    );
  });

  test('1年前・2年前の今日の投稿を、近い年から集める', () async {
    final repo = FakeXArchiveRepository([
      post('a', 2025, 11, 11, h: 9),
      post('b', 2025, 11, 11, h: 20),
      post('c', 2024, 11, 11),
      post('x', 2025, 11, 12), // 別の日
    ]);
    final recall = await XArchiveRecallBuilder(repo).build(today);

    expect(recall.years.map((y) => y.yearsAgo), [1, 2]);
    expect(recall.years[0].posts.map((p) => p.tweetId), ['a', 'b']); // 古い順
    expect(recall.years[1].posts.map((p) => p.tweetId), ['c']);
  });

  test('日本時間の日付で数える(UTCでは前日の朝の投稿が、今日に入る)', () async {
    // 日本時間2025/11/11 00:30 は、UTCでは 2025/11/10 15:30
    final repo = FakeXArchiveRepository([post('a', 2025, 11, 11, h: 0)]);
    final recall = await XArchiveRecallBuilder(repo).build(today);
    expect(recall.years.single.posts.single.tweetId, 'a');
  });

  test('リツイート・リプライ・短い投稿は出さない', () async {
    final repo = FakeXArchiveRepository([
      post('rt', 2025, 11, 11, kind: XArchivePostKind.retweet),
      post('re', 2025, 11, 11, kind: XArchivePostKind.reply),
      post('short', 2025, 11, 11, text: 'ねむい'),
    ]);
    final recall = await XArchiveRecallBuilder(repo).build(today);
    expect(recall.years, isEmpty);
  });

  test('1つの年からは5件まで', () async {
    final repo = FakeXArchiveRepository([
      for (var i = 0; i < 9; i++) post('p$i', 2025, 11, 11, h: i + 1),
    ]);
    final recall = await XArchiveRecallBuilder(repo).build(today);
    expect(recall.years.single.posts, hasLength(5));
    expect(recall.years.single.posts.first.tweetId, 'p0');
  });

  test('今日の分が少ないと、ランダムな投稿を足して、同じ日なら同じ結果になる', () async {
    final repo = FakeXArchiveRepository([
      post('today', 2025, 11, 11),
      for (var i = 1; i <= 30; i++) post('o$i', 2023, 5, i),
    ]);
    final builder = XArchiveRecallBuilder(repo);
    final first = await builder.build(today);
    final second = await builder.build(today);

    expect(first.years.single.posts.single.tweetId, 'today');
    expect(first.randoms, hasLength(4)); // 合計5件になるまで
    expect(first.randoms.map((p) => p.tweetId), isNot(contains('today')));
    expect(
      second.randoms.map((p) => p.tweetId),
      first.randoms.map((p) => p.tweetId),
    );
    // ほかの日は、別の投稿になりうる(同じ日付の結果は変わらない)
    expect(first.randoms.map((p) => p.tweetId).toSet(), hasLength(4));
  });

  test('うるう日は、その日がない年を飛ばす', () async {
    final repo = FakeXArchiveRepository([
      post('leap', 2024, 2, 29),
      post('mar1', 2025, 3, 1), // 2025年の2月29日と取り違えない
    ]);
    final recall = await XArchiveRecallBuilder(
      repo,
    ).build(DateTime(2028, 2, 29));
    expect(recall.years.map((y) => y.yearsAgo), [4]);
    expect(recall.years.single.posts.single.tweetId, 'leap');
  });

  test('取り込みがなければ、空', () async {
    final recall = await XArchiveRecallBuilder(
      FakeXArchiveRepository([]),
    ).build(today);
    expect(recall.isEmpty, isTrue);
  });
}
