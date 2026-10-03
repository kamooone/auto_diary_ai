import '../entities/shared_post.dart';

abstract class ShareRepository {
  /// 共有されたURLから投稿本文を取得(取得できない場合はnull)
  Future<String?> fetchText(String url);

  Future<void> save(SharedPost post);
  Future<List<SharedPost>> findByDate(DateTime date);
}