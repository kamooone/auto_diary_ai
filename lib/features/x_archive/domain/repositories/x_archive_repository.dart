import '../entities/x_archive_post.dart';

/// 取り込みの結果
class XArchiveImportResult {
  /// 新しく保存した件数
  final int added;

  /// 取り込み済みだったので飛ばした件数
  final int skipped;

  const XArchiveImportResult({required this.added, required this.skipped});
}

abstract class XArchiveRepository {
  /// 投稿を保存する。投稿IDが保存済みのものは飛ばす(何度取り込んでも増えない)
  ///
  /// [onProgress] には、処理し終えた件数(飛ばした分を含む)が渡される
  Future<XArchiveImportResult> import(
    List<XArchivePost> posts, {
    void Function(int done)? onProgress,
  });

  /// 保存した投稿の件数
  Future<int> count();

  /// 保存した投稿を、新しい順に取得する。[year] を渡すと、その年(日本時間)だけ
  Future<List<XArchivePost>> findPage({
    required int offset,
    required int limit,
    int? year,
  });

  /// 保存した投稿の、年(日本時間)ごとの件数
  Future<Map<int, int>> countByYear();

  /// 保存した投稿をすべて消す
  Future<void> deleteAll();
}
