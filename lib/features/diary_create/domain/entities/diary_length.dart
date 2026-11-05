/// ふつうのAI日記の、文字数の目安(任意)
///
/// AIへの目安のお願いで、この通りの文字数になるとは限らない
enum DiaryLength {
  none("指定しない", 0),
  about200("200文字", 200),
  about500("500文字", 500),
  about1000("1,000文字", 1000),
  about2000("2,000文字", 2000),
  about3000("3,000文字", 3000);

  const DiaryLength(this.label, this.chars);

  final String label;

  /// 目安の文字数(指定しない場合は0)
  final int chars;
}
