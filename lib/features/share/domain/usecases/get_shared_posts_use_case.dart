import '../entities/shared_post.dart';
import '../repositories/share_repository.dart';

class GetSharedPostsUseCase {
  final ShareRepository repository;

  GetSharedPostsUseCase(this.repository);

  Future<List<SharedPost>> execute(DateTime date) {
    return repository.findByDate(date);
  }
}