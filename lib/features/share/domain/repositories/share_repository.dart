import '../entities/shared_post.dart';

abstract class ShareRepository {
  /// 共有されたURLから投稿本文を取得(取得できない場合はnull)
  Future<String?> fetchText(String url);

  Future<void> save(SharedPost post);
  Future<List<SharedPost>> findByDate(DateTime date);

  /// 保存したすべての投稿を、新しい順に取得
  Future<List<SharedPost>> findAll();

  /// 保存済みの投稿(idあり)の内容を更新する
  Future<void> update(SharedPost post);

  Future<void> delete(int id);
}
