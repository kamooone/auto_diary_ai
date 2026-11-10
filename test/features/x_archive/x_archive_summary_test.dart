import 'package:auto_diary_ai/features/x_archive/domain/entities/x_archive_post.dart';
import 'package:auto_diary_ai/features/x_archive/domain/services/x_archive_summary.dart';
import 'package:flutter_test/flutter_test.dart';

XArchivePost _post(String id, DateTime utc) => XArchivePost(
      tweetId: id,
      text: 't',
      createdAt: utc,
      kind: XArchivePostKind.post,
    );

void main() {
  test('年は日本時間で数える(UTCの大晦日15時は、日本では元日)', () {
    expect(xArchiveYearJst(DateTime.utc(2025, 12, 31, 14, 59)), 2025);
    expect(xArchiveYearJst(DateTime.utc(2025, 12, 31, 15, 0)), 2026);
  });

  test('年ごとの件数を数える', () {
    final posts = [
      _post('1', DateTime.utc(2024, 5, 1)),
      _post('2', DateTime.utc(2024, 6, 1)),
      _post('3', DateTime.utc(2025, 1, 10)),
    ];
    expect(countByYear(posts), {2024: 2, 2025: 1});
  });

  test('選んだ年だけを残す', () {
    final posts = [
      _post('1', DateTime.utc(2024, 5, 1)),
      _post('2', DateTime.utc(2025, 1, 10)),
    ];
    expect(filterByYears(posts, {2025}).map((p) => p.tweetId), ['2']);
    expect(filterByYears(posts, {}), isEmpty);
  });
}
