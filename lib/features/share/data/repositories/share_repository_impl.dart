import 'package:isar/isar.dart';
import '../../domain/repositories/share_repository.dart';
import '../datasources/ogp_fetcher.dart';
import '../../domain/entities/shared_post.dart';
import '../models/shared_post_entity.dart';

class ShareRepositoryImpl implements ShareRepository {
  final OgpFetcher ogp;
  final Isar isar;

  ShareRepositoryImpl(this.ogp, this.isar);

  @override
  Future<SharedPost> fetchPost(String url) async {
    final text = await ogp.fetchText(url);

    return SharedPost(
      url: url,
      text: text ?? '',
      receivedAt: DateTime.now(),
    );
  }

  @override
  Future<void> save(SharedPost post) async {
    final entity = SharedPostEntity()
      ..url = post.url
      ..text = post.text
      ..receivedAt = post.receivedAt;

    await isar.writeTxn(() async {
      await isar.sharedPostEntitys.put(entity);
    });
  }
}