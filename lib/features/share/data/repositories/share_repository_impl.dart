import 'package:flutter/cupertino.dart';
import 'package:isar/isar.dart';
import '../../domain/repositories/share_repository.dart';
import '../datasources/ogp_fetcher.dart';
import '../../domain/entities/shared_post.dart';
import '../models/shared_post_model.dart';

class ShareRepositoryImpl implements ShareRepository {
  final OgpFetcher ogp;
  final Isar isar;

  ShareRepositoryImpl(this.ogp, this.isar);

  @override
  Future<String?> fetchText(String url) {
    return ogp.fetchText(url);
  }

  @override
  Future<void> save(SharedPost post) async {
    final entity = SharedPostModel()
      ..url = post.url
      ..text = post.text
      ..receivedAt = post.receivedAt;

    try {
      await isar.writeTxn(() async {
        await isar.sharedPostModels.put(entity);
      });
    } catch (e, stackTrace) {
      debugPrint('DB保存失敗: $e');
      debugPrintStack(stackTrace: stackTrace);
      rethrow;
    }
  }

  @override
  Future<List<SharedPost>> findByDate(DateTime date) async {
    final start = DateTime(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1));

    try {
      final models = await isar.sharedPostModels
          .filter()
          .receivedAtBetween(start, end)
          .findAll();

      return models.map(_toPost).toList();
    } catch (e, stackTrace) {
      debugPrint('DB取得失敗: $e');
      debugPrintStack(stackTrace: stackTrace);
      rethrow;
    }
  }

  @override
  Future<List<SharedPost>> findAll() async {
    try {
      final models =
          await isar.sharedPostModels.where().sortByReceivedAtDesc().findAll();

      return models.map(_toPost).toList();
    } catch (e, stackTrace) {
      debugPrint('DB取得失敗: $e');
      debugPrintStack(stackTrace: stackTrace);
      rethrow;
    }
  }

  @override
  Future<void> update(SharedPost post) async {
    final id = post.id;
    if (id == null) throw ArgumentError('idのない投稿は更新できません');

    final entity = SharedPostModel()
      ..id = id
      ..url = post.url
      ..text = post.text
      ..receivedAt = post.receivedAt;

    try {
      await isar.writeTxn(() async {
        await isar.sharedPostModels.put(entity);
      });
    } catch (e, stackTrace) {
      debugPrint('DB更新失敗: $e');
      debugPrintStack(stackTrace: stackTrace);
      rethrow;
    }
  }

  @override
  Future<void> delete(int id) async {
    try {
      await isar.writeTxn(() async {
        await isar.sharedPostModels.delete(id);
      });
    } catch (e, stackTrace) {
      debugPrint('DB削除失敗: $e');
      debugPrintStack(stackTrace: stackTrace);
      rethrow;
    }
  }

  SharedPost _toPost(SharedPostModel model) {
    return SharedPost(
      id: model.id,
      url: model.url,
      text: model.text,
      receivedAt: model.receivedAt,
    );
  }
}