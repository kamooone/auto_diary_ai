/// 「日記を1つにする」ときの、書き方
enum SummaryStyle {
  reading("読み物(ブログ風)", "テーマごとに章立てして、細部を残しながら読み物にします"),
  chronicle("時系列の記録", "日付順に、日ごとの出来事を省略せずに書きます(長くなります)"),
  brief("短い振り返り", "流れと印象に残った出来事だけを、短くまとめます"),
  list("出来事の一覧", "日付ごとの出来事を、箇条書きで並べます"),
  custom("自分で指定", "書き方を自分で書いて指定します");

  const SummaryStyle(this.label, this.description);

  final String label;
  final String description;

  /// 保存した名前から戻す(分からない場合は、最初の選択の読み物)
  static SummaryStyle fromName(Object? name) {
    return values.where((e) => e.name == name).firstOrNull ?? reading;
  }
}
