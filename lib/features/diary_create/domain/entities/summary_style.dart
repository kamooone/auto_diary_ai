/// 「日記を1つにする」ときの、書き方
enum SummaryStyle {
  // 並べる順番が、画面に表示される順番
  chronicle("日記を連結させる", "AIを使わず、日記を日付順にそのままつなげます(トークンを使いません)"),
  list("出来事の一覧", "日付ごとの出来事を、箇条書きで並べます"),
  brief("読み物(簡単なログ風)", "印象に残った出来事を日付つきで、簡潔な読み物にします"),
  reading("読み物(ブログ風)", "テーマごとに章立てして、細部を残しながら読み物にします"),
  custom("自分で指定", "書き方を自分で書いて指定します");

  const SummaryStyle(this.label, this.description);

  final String label;
  final String description;

  /// 保存した名前から戻す(分からない場合は、最初の選択の読み物)
  static SummaryStyle fromName(Object? name) {
    return values.where((e) => e.name == name).firstOrNull ?? reading;
  }
}
