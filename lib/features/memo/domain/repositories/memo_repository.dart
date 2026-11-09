import '../entities/memo.dart';

abstract class MemoRepository {
  /// 新しいメモを保存する(idは、保存時に決まる)
  Future<void> save(Memo memo);

  /// 保存済みのメモ(idあり)の内容を更新する
  Future<void> update(Memo memo);

  Future<void> delete(int id);

  /// 保存したすべてのメモを、新しい順に取得
  Future<List<Memo>> findAll();

  /// [start]以上[end]未満のメモを、古い順に取得
  Future<List<Memo>> findBetween(DateTime start, DateTime end);
}
