import '../entities/shared_post.dart';

abstract class ShareRepository {
  Future<SharedPost> fetchPost(String url);
  Future<void> save(SharedPost post);
}