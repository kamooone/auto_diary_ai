import 'package:auto_diary_ai/features/share/domain/entities/shared_post.dart';
import '../repositories/share_repository.dart';

class ShareTweetUseCase {
  final ShareRepository repository;

  ShareTweetUseCase(this.repository);

  Future<SharedPost> execute(String url) async {
    final text = await repository.fetchText(url);

    return SharedPost(
      url: url,
      text: text ?? '',
      receivedAt: DateTime.now(),
    );
  }
}