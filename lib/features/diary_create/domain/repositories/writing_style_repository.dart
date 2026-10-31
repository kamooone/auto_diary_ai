/// 文体の希望を保存・取得する
abstract class WritingStyleRepository {
  /// 保存された文章(一度も保存していない場合は、最初のサンプル文)
  Future<String> load();

  Future<void> save(String text);

  /// 最初のサンプル文に戻す
  Future<void> reset();
}
