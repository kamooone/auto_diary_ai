import 'package:isar/isar.dart';

import '../../domain/entities/x_archive_post.dart';
import '../../domain/entities/x_archive_post_filter.dart';
import '../../domain/repositories/x_archive_repository.dart';
import '../../domain/services/x_archive_summary.dart';
import '../models/x_archive_post_model.dart';

class XArchiveRepositoryImpl implements XArchiveRepository {
  final Isar isar;

  /// 1回の書き込みにまとめる件数(多いほど速いが、メモリを使う)
  static const batchSize = 500;

  XArchiveRepositoryImpl(this.isar);

  @override
  Future<XArchiveImportResult> import(
    List<XArchivePost> posts, {
    void Function(int done)? onProgress,
  }) async {
    var added = 0;
    var skipped = 0;

    for (var i = 0; i < posts.length; i += batchSize) {
      final end = i + batchSize < posts.length ? i + batchSize : posts.length;
      final batch = posts.sublist(i, end);

      // 保存済みの投稿IDを、まとめて調べる
      final existing = (await isar.xArchivePostModels
              .where()
              .anyOf(batch.map((p) => p.tweetId), (q, id) => q.tweetIdEqualTo(id))
              .findAll())
          .map((m) => m.tweetId)
          .toSet();
      final fresh = <XArchivePostModel>[];
      final seen = <String>{};
      for (final post in batch) {
        // 保存済み、または同じ取り込みの中で重複している投稿は飛ばす
        if (existing.contains(post.tweetId) || !seen.add(post.tweetId)) {
          skipped++;
        } else {
          fresh.add(_toModel(post));
        }
      }

      if (fresh.isNotEmpty) {
        await isar.writeTxn(() async {
          await isar.xArchivePostModels.putAll(fresh);
        });
        added += fresh.length;
      }
      onProgress?.call(end);
    }

    return XArchiveImportResult(added: added, skipped: skipped);
  }

  @override
  Future<int> count() => isar.xArchivePostModels.count();

  @override
  Future<List<XArchivePost>> findPage({
    required int offset,
    required int limit,
    XArchivePostFilter filter = XArchivePostFilter.none,
  }) async {
    final models = await _filtered(filter)
        .sortByCreatedAtDesc()
        .offset(offset)
        .limit(limit)
        .findAll();
    return models.map(_toPost).toList();
  }

  @override
  Future<int> countMatching(XArchivePostFilter filter) {
    return _filtered(filter).count();
  }

  QueryBuilder<XArchivePostModel, XArchivePostModel, QAfterFilterCondition>
      _filtered(XArchivePostFilter filter) {
    final from = filter.from;
    final to = filter.to;
    final words = filter.words;
    return isar.xArchivePostModels
        .filter()
        .optional(
          from != null && to != null,
          (q) => q.createdAtBetween(from!, to!, includeUpper: false),
        )
        .optional(
          words.isNotEmpty,
          (q) => q.allOf(
            words,
            (q, word) => q.textContains(word, caseSensitive: false),
          ),
        );
  }

  QueryBuilder<XArchivePostModel, XArchivePostModel, QAfterFilterCondition>
      _originals() {
    return isar.xArchivePostModels
        .filter()
        .kindEqualTo(XArchivePostKind.post.name)
        .or()
        .kindEqualTo(XArchivePostKind.quote.name);
  }

  @override
  Future<int> countOriginals() => _originals().count();

  @override
  Future<List<XArchivePost>> findOriginals({
    required int offset,
    required int limit,
  }) async {
    final models = await _originals()
        .sortByCreatedAtDesc()
        .offset(offset)
        .limit(limit)
        .findAll();
    return models.map(_toPost).toList();
  }

  @override
  Future<XArchivePost?> find(String tweetId) async {
    final model =
        await isar.xArchivePostModels.where().tweetIdEqualTo(tweetId).findFirst();
    return model == null ? null : _toPost(model);
  }

  @override
  Future<void> updatePhotoIds(String tweetId, List<String>? photoIds) async {
    final model =
        await isar.xArchivePostModels.where().tweetIdEqualTo(tweetId).findFirst();
    if (model == null) return;
    model.photoIds = photoIds;
    await isar.writeTxn(() async {
      await isar.xArchivePostModels.put(model);
    });
  }

  @override
  Future<Map<int, int>> countByYear() async {
    final dates = await isar.xArchivePostModels
        .where()
        .createdAtProperty()
        .findAll();
    final counts = <int, int>{};
    for (final d in dates) {
      final y = xArchiveYearJst(d);
      counts[y] = (counts[y] ?? 0) + 1;
    }
    return counts;
  }

  @override
  Future<void> deleteAll() async {
    await isar.writeTxn(() async {
      await isar.xArchivePostModels.clear();
    });
  }

  XArchivePost _toPost(XArchivePostModel m) {
    return XArchivePost(
      tweetId: m.tweetId,
      text: m.text,
      createdAt: m.createdAt,
      kind: XArchivePostKind.values.firstWhere(
        (k) => k.name == m.kind,
        orElse: () => XArchivePostKind.post,
      ),
      replyToScreenName: m.replyToScreenName,
      imageFileNames: m.imageFileNames,
      imageAspectRatios: m.imageAspectRatios,
      hasVideo: m.hasVideo,
      photoIds: m.photoIds,
    );
  }

  XArchivePostModel _toModel(XArchivePost post) {
    return XArchivePostModel()
      ..tweetId = post.tweetId
      ..text = post.text
      ..createdAt = post.createdAt
      ..kind = post.kind.name
      ..replyToScreenName = post.replyToScreenName
      ..imageFileNames = post.imageFileNames
      ..imageAspectRatios = post.imageAspectRatios
      ..hasVideo = post.hasVideo
      ..photoIds = post.photoIds;
  }
}
