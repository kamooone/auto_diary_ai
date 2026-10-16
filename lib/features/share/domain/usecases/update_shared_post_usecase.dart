import '../entities/shared_post.dart';
import '../repositories/share_repository.dart';

class UpdateSharedPostUseCase {
  final ShareRepository repository;

  UpdateSharedPostUseCase(this.repository);

  /// 投稿の本文と日時を修正する(URLは変えない)
  Future<void> execute(
    SharedPost post, {
    required String text,
    required DateTime receivedAt,
  }) {
    if (post.id == null) {
      throw ArgumentError('保存されていない投稿は修正できません');
    }

    return repository.update(
      SharedPost(
        id: post.id,
        url: post.url,
        text: text,
        receivedAt: receivedAt,
      ),
    );
  }
}
