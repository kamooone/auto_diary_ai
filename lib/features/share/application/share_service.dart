import '../domain/entities/shared_post.dart';
import '../domain/usecases/share_tweet_usecase.dart';

class ShareService {
  final ShareTweetUseCase useCase;

  ShareService(this.useCase);

  Future<SharedPost> handle(String url) async {
    return await useCase.execute(url);
  }
}