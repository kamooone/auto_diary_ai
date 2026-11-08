import '../entities/diary_style.dart';

abstract class DiaryStyleRepository {
  /// 前回選んだ書き方(一度も保存していない場合は、日記)
  ///
  /// 「自分で指定」に書いた指示は、保存しない。前回が「自分で指定」だったときは、日記に戻す
  Future<DiaryStyle> load();

  Future<void> save(DiaryStyle style);
}
