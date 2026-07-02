import '../entities/shared_post.dart';

abstract class ShareRepository {
  Future<void> save(SharedPost post);
  Future<List<SharedPost>> findByDate(DateTime date);
}