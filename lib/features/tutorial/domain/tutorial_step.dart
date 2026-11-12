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
  });

  /// 部品を指さずに、画面の中ほどに吹き出しだけを出す(アプリの紹介など)
  const TutorialStep.intro({required this.title, required this.body})
    : target = null,
      bubbleAbove = false,
      circle = false;

  /// 明るくする部品(画面にあるときだけ、場所を取れる)。nullなら、部品は指さない
  final GlobalKey? target;

  final String title;
  final String body;

  /// 吹き出しを、部品の上に出すか(falseなら下)。画面の下にある部品は、上に出す
  final bool bubbleAbove;

  /// 明るくする形を、円にするか(falseなら角丸の四角)
  final bool circle;
}
