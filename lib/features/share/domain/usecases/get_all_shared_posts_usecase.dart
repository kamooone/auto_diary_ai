import '../entities/shared_post.dart';
import '../repositories/share_repository.dart';

class GetAllSharedPostsUseCase {
  final ShareRepository repository;

  GetAllSharedPostsUseCase(this.repository);

  /// 保存したすべての投稿を、新しい順に取得する
  Future<List<SharedPost>> execute() {
    return repository.findAll();
  }
}
