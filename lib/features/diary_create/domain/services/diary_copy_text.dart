/// 日記を、ほかのアプリに貼り付けるための文章にする
class DiaryCopyText {
  DiaryCopyText._();

  /// タイトルと本文を、空行で区切って1つの文章にする
  /// (タイトルが空の場合は、本文だけにする)
  static String format({required String title, required String content}) {
    final trimmedTitle = title.trim();
    final trimmedContent = content.trim();

    if (trimmedTitle.isEmpty) return trimmedContent;
    if (trimmedContent.isEmpty) return trimmedTitle;

    return "$trimmedTitle\n\n$trimmedContent";
  }
}
