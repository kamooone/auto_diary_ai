import '../entities/summary_style.dart';

abstract class SummaryStyleRepository {
  /// 前回選んだ書き方(一度も保存していない場合は、読み物)
  ///
  /// 「自分で指定」に書いた指示は、保存しない。前回が「自分で指定」だったときは、読み物に戻す
  Future<SummaryStyle> load();

  Future<void> save(SummaryStyle style);
}
