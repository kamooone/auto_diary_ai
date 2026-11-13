import 'package:flutter/widgets.dart';

/// スポットライト式のチュートリアルの、1ステップ
///
/// [target]の部品だけを明るくして、そのそばに[title]と[body]の吹き出しを出す。
/// 今は文字だけ。あとから画像を入れるときは、ここに項目を足す
class TutorialStep {
  const TutorialStep({
    required GlobalKey this.target,
    required this.title,
    required this.body,
    this.bubbleAbove = false,
    this.circle = false,
    this.scrollAlignment,
  });

  /// 部品を指さずに、画面の中ほどに吹き出しだけを出す(アプリの紹介など)
  const TutorialStep.intro({required this.title, required this.body})
    : target = null,
      bubbleAbove = false,
      circle = false,
      scrollAlignment = null;

  /// 明るくする部品(画面にあるときだけ、場所を取れる)。nullなら、部品は指さない
  final GlobalKey? target;

  final String title;
  final String body;

  /// 吹き出しを、部品の上に出すか(falseなら下)。画面の下にある部品は、上に出す
  final bool bubbleAbove;

  /// 明るくする形を、円にするか(falseなら角丸の四角)
  final bool circle;

  /// 画面をスクロールして、部品をどこに置くか(0で上端、1で下端)。
  /// 決めなければ、吹き出しが下なら上寄り、上なら下寄りにする。
  /// 縦に長い部品は、吹き出しが画面からはみ出さないよう、上端(0)にするとよい
  final double? scrollAlignment;
}
