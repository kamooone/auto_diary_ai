/// ふつうのAI日記を書いてもらうときの、書き方
enum DiaryStyle {
  diary("日記", "その日の出来事を、1本の日記の文章にします"),
  blog("ブログ風", "見出しをつけて、読み物のように書きます(旅行や複数日の期間に向きます)"),
  record("時系列の記録", "時刻の順に、出来事を淡々と並べます"),
  bullets("箇条書き", "出来事を、箇条書きで並べます"),
  custom("自分で指定", "書き方を自分で書いて指定します");

  const DiaryStyle(this.label, this.description);

  final String label;
  final String description;

  /// 保存した名前から戻す(分からない場合は、最初の選択の日記)
  static DiaryStyle fromName(Object? name) {
    return values.where((e) => e.name == name).firstOrNull ?? diary;
  }
}
