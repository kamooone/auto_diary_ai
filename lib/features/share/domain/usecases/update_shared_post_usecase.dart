import '../entities/shared_post.dart';
import '../repositories/share_repository.dart';

class UpdateSharedPostUseCase {
  final ShareRepository repository;

  UpdateSharedPostUseCase(this.repository);

  /// 投稿の本文、日時、結びつけた写真を修正する(URLは変えない)
  ///
  /// [photoIds] を渡さなければ、写真はそのまま
  Future<void> execute(
    SharedPost post, {
    required String text,
    required DateTime receivedAt,
    List<String>? photoIds,
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
        photoIds: photoIds ?? post.photoIds,
      ),
    );
  }
}
