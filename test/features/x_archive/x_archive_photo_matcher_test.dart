import 'package:auto_diary_ai/features/diary_create/domain/entities/photo.dart';
import 'package:auto_diary_ai/features/x_archive/domain/entities/x_archive_post.dart';
import 'package:auto_diary_ai/features/x_archive/domain/services/x_archive_photo_matcher.dart';
import 'package:flutter_test/flutter_test.dart';

final _posted = DateTime.utc(2026, 5, 1, 3, 0);

XArchivePost _post({required List<double> ratios, List<String>? names}) {
  return XArchivePost(
    tweetId: '1',
    text: 't',
    createdAt: _posted,
    kind: XArchivePostKind.post,
    imageFileNames:
        names ?? [for (var i = 0; i < ratios.length; i++) '1-$i.jpg'],
    imageAspectRatios: ratios,
  );
}

Photo _photo(String id, Duration beforePost, {int? w, int? h}) =>
    Photo(id: id, createdAt: _posted.subtract(beforePost), width: w, height: h);

void main() {
  const matcher = XArchivePhotoMatcher();

  test('探す期間は、投稿の24時間前から1時間後まで', () {
    final r = matcher.window(_posted);
    expect(r.from.toUtc(), _posted.subtract(const Duration(hours: 24)));
    expect(r.to.toUtc(), _posted.add(const Duration(hours: 1)));
  });

  test('画像のない投稿には、候補を出さない', () {
    final post = _post(ratios: []);
    expect(
      matcher.pick(post, [_photo('a', const Duration(minutes: 5))]),
      isEmpty,
    );
  });

  test('投稿の枚数ぶんまで、投稿に近い写真を選ぶ', () {
    final post = _post(ratios: [0, 0]);
    final picked = matcher.pick(post, [
      _photo('far', const Duration(hours: 10)),
      _photo('near', const Duration(minutes: 5)),
      _photo('mid', const Duration(hours: 1)),
    ]);
    expect(picked.map((p) => p.id), ['mid', 'near']); // 撮影の古い順
  });

  test('縦横比が合わない写真は選ばない', () {
    final post = _post(ratios: [1.5]); // 横長
    final picked = matcher.pick(post, [
      _photo('tall', const Duration(minutes: 1), w: 1000, h: 2000),
      _photo('wide', const Duration(minutes: 30), w: 3000, h: 2000),
    ]);
    expect(picked.map((p) => p.id), ['wide']);
  });

  test('写真の大きさが分からないときは、縦横比で絞らない', () {
    final post = _post(ratios: [1.5]);
    final picked = matcher.pick(post, [
      _photo('unknown', const Duration(minutes: 1)),
    ]);
    expect(picked.map((p) => p.id), ['unknown']);
  });

  test('同じ写真を2枚分に使わない', () {
    final post = _post(ratios: [0, 0]);
    final picked = matcher.pick(post, [
      _photo('only', const Duration(minutes: 1)),
    ]);
    expect(picked, hasLength(1));
  });
}
