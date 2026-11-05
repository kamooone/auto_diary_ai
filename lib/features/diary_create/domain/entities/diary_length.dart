/// 日記の文字数の目安(任意)
///
/// AIへの目安のお願いで、この通りの文字数になるとは限らない
class DiaryLength {
  const DiaryLength._();

  /// 指定できる文字数の上限。
  /// 長すぎると、60秒の制限で時間切れになったり、トークンを使いすぎたりするため
  static const max = 3000;

  /// 入力された文字列を、文字数にする(空・数字でないときは0=指定しない。上限を超えたら上限)
  static int parse(String text) {
    final value = int.tryParse(text.trim()) ?? 0;
    if (value <= 0) return 0;
    return value > max ? max : value;
  }

  /// 入力された文字列が、上限を超えているか
  static bool isOver(String text) => (int.tryParse(text.trim()) ?? 0) > max;
}
