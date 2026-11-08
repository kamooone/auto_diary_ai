import '../entities/shared_post.dart';
import '../repositories/share_repository.dart';

class DeleteSharedPostUseCase {
  final ShareRepository repository;

  DeleteSharedPostUseCase(this.repository);

  Future<void> execute(SharedPost post) {
    final id = post.id;
    if (id == null) {
      throw ArgumentError('保存されていない投稿は削除できません');
    }

    return repository.delete(id);
  }
}
