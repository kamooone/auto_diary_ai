import '../entities/summary_style.dart';

/// 日記を1つにするときの、前回の書き方の選択
class SummaryStyleSetting {
  const SummaryStyleSetting({
    this.style = SummaryStyle.reading,
    this.customInstruction = '',
  });

  final SummaryStyle style;

  /// 「自分で指定」に書いた、書き方の指示
  final String customInstruction;
}

abstract class SummaryStyleRepository {
  /// 前回の選択(一度も保存していない場合は、読み物)
  Future<SummaryStyleSetting> load();

  Future<void> save(SummaryStyleSetting setting);
}
