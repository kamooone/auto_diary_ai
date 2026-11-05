/// 日記の文字数の目安(任意)
///
/// 文字数の上限は設けない。AIへの目安のお願いで、この通りの文字数になるとは限らない
class DiaryLength {
  const DiaryLength._();

  /// 入力できる桁数(数が大きすぎて扱えなくならないための、技術的な制限)
  static const maxDigits = 9;

  /// 入力された文字列を、文字数にする(空・数字でないときは0=指定しない)
  static int parse(String text) {
    final value = int.tryParse(text.trim()) ?? 0;
    return value > 0 ? value : 0;
  }
}
