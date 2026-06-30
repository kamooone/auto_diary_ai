import '../../domain/repositories/share_repository.dart';
import '../datasources/ogp_fetcher.dart';
import '../../domain/entities/shared_post.dart';

class ShareRepositoryImpl implements ShareRepository {
  final OgpFetcher ogp;

  ShareRepositoryImpl(this.ogp);

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
    // とりあえず未実装でもOK（後でDBとかに逃がす）
    throw UnimplementedError();
  }
}