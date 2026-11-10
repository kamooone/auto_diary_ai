import 'package:auto_diary_ai/features/x_archive/domain/entities/x_archive_post.dart';
import 'package:auto_diary_ai/features/x_archive/domain/entities/x_archive_post_filter.dart';
import 'package:auto_diary_ai/features/x_archive/domain/repositories/x_archive_repository.dart';
import 'package:auto_diary_ai/features/x_archive/domain/services/x_archive_summary.dart';

/// テスト用の、メモリ上のリポジトリ
class FakeXArchiveRepository implements XArchiveRepository {
  final List<XArchivePost> posts;

  FakeXArchiveRepository(this.posts);

  List<XArchivePost> _sorted() =>
      [...posts]..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  bool _isOriginal(XArchivePost p) =>
      p.kind == XArchivePostKind.post || p.kind == XArchivePostKind.quote;

  @override
  Future<XArchiveImportResult> import(
    List<XArchivePost> posts, {
    void Function(int done)? onProgress,
  }) async {
    this.posts.addAll(posts);
    return XArchiveImportResult(added: posts.length, skipped: 0);
  }

  @override
  Future<int> count() async => posts.length;

  @override
  Future<List<XArchivePost>> findPage({
    required int offset,
    required int limit,
    XArchivePostFilter filter = XArchivePostFilter.none,
  }) async {
    final from = filter.from;
    final to = filter.to;
    final matched = _sorted().where((p) {
      if (from != null && p.createdAt.isBefore(from)) return false;
      if (to != null && !p.createdAt.isBefore(to)) return false;
      return true;
    }).toList();
    return matched.skip(offset).take(limit).toList();
  }

  @override
  Future<int> countMatching(XArchivePostFilter filter) async =>
      (await findPage(offset: 0, limit: 1 << 30, filter: filter)).length;

  @override
  Future<int> countOriginals() async => posts.where(_isOriginal).length;

  @override
  Future<List<XArchivePost>> findOriginals({
    required int offset,
    required int limit,
  }) async => _sorted().where(_isOriginal).skip(offset).take(limit).toList();

  @override
  Future<XArchivePost?> find(String tweetId) async {
    for (final p in posts) {
      if (p.tweetId == tweetId) return p;
    }
    return null;
  }

  @override
  Future<void> updatePhotoIds(String tweetId, List<String>? photoIds) async {}

  @override
  Future<Map<int, int>> countByYear() async => {...countByYearOf(posts)};

  @override
  Future<void> deleteAll() async => posts.clear();
}

Map<int, int> countByYearOf(List<XArchivePost> posts) {
  final counts = <int, int>{};
  for (final p in posts) {
    final y = xArchiveYearJst(p.createdAt);
    counts[y] = (counts[y] ?? 0) + 1;
  }
  return counts;
}
