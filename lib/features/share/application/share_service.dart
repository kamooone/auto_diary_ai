import '../domain/entities/shared_post.dart';
import '../domain/usecases/get_shared_posts_use_case.dart';
import '../domain/usecases/save_shared_post_usecase.dart';
import '../domain/usecases/share_tweet_usecase.dart';

class ShareService {
  final ShareTweetUseCase _shareTweetUseCase;
  final SaveSharedPostUseCase _saveSharedPostUseCase;
  final GetSharedPostsUseCase _getSharedPostsUseCase;

  ShareService(
      this._shareTweetUseCase,
      this._saveSharedPostUseCase,
      this._getSharedPostsUseCase,
      );

  Future<SharedPost> handle(String url) {
    return _shareTweetUseCase.execute(url);
  }

  Future<void> save(
      SharedPost post,
      DateTime selectedDate,
      ) {
    return _saveSharedPostUseCase.execute(
      url: post.url,
      text: post.text,
      receivedAt: selectedDate,
    );
  }

  Future<List<SharedPost>> getPosts(DateTime date) {
    return _getSharedPostsUseCase.execute(date);
  }
}