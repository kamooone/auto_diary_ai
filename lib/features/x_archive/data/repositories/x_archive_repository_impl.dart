import 'package:isar/isar.dart';

import '../../domain/entities/x_archive_post.dart';
import '../../domain/repositories/x_archive_repository.dart';
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
  Future<void> deleteAll() async {
    await isar.writeTxn(() async {
      await isar.xArchivePostModels.clear();
    });
  }

  XArchivePostModel _toModel(XArchivePost post) {
    return XArchivePostModel()
      ..tweetId = post.tweetId
      ..text = post.text
      ..createdAt = post.createdAt
      ..kind = post.kind.name
      ..replyToScreenName = post.replyToScreenName
      ..imageFileNames = post.imageFileNames
      ..hasVideo = post.hasVideo;
  }
}
