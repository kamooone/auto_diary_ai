import 'package:auto_diary_ai/features/share/domain/entities/shared_post.dart';
import '../../data/datasources/ogp_fetcher.dart';

class ShareTweetUseCase {
  final OgpFetcher ogpFetcher;

  ShareTweetUseCase(this.ogpFetcher);

  Future<SharedPost> execute(String url) async {
    final text = await ogpFetcher.fetchText(url);

    return SharedPost(
      url: url,
      text: text ?? '',
      receivedAt: DateTime.now(),
    );
  }
}