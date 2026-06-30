import '../entities/shared_post.dart';
import '../repositories/share_repository.dart';

class SaveSharedPostUseCase {
  final ShareRepository repository;

  SaveSharedPostUseCase(this.repository);

  Future<void> execute({
    required String url,
    required String text,
    required DateTime receivedAt,
  }) async {
    final post = SharedPost(
      url: url,
      text: text,
      receivedAt: receivedAt,
    );

    await repository.save(post);
  }
}