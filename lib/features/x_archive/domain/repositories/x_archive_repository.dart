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
  Future<XArchiveImportResult> import(List<XArchivePost> posts);

  /// 保存した投稿の件数
  Future<int> count();

  /// 保存した投稿をすべて消す
  Future<void> deleteAll();
}
