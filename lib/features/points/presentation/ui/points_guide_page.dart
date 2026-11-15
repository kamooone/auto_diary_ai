import 'package:flutter/material.dart';

import '../../../../core/widgets/step_guide.dart';

/// ポイントを貯めて、トークンに交換し、このアプリで使うまでの流れ
/// (「ポイント・トークン」の画面の右上から開く)
class PointsGuidePage extends StatelessWidget {
  const PointsGuidePage({super.key});

  static const _steps = [
    GuideStep(
      title: "Webで、アカウントを作る",
      body: "「Webを開く」を押すと、専用のWebページが開きます。\n"
          "そこで、アカウントを作成します。",
    ),
    GuideStep(
      title: "ゲームで、ポイントを貯める",
      body: "このアプリの開発者が作ったゲームで遊ぶと、ポイントが貯まります。\n"
          "ゲームの一覧は、専用のWebページに載っています。",
    ),
    GuideStep(
      title: "ポイントを、トークンに交換する",
      body: "貯めたポイントは、Webページで、トークンに交換できます。\n"
          "トークンは、AIが日記を書くときに使う、使用量の単位です。",
    ),
    GuideStep(
      title: "アプリで、コードを発行する",
      body: "このアプリの「ポイント・トークン」の画面で、「コードを発行する」を押すと、"
          "6桁のコードが表示されます。\n"
          "コードの有効期限は、10分です。",
    ),
    GuideStep(
      title: "Webページで、コードを入力する",
      body: "Webページにログインして、コードを入力すると、このアプリとアカウントが紐づけされます。",
    ),
    GuideStep(
      title: "トークンが使えるようになります",
      body: "紐づけされると、この画面に、トークンの残高が表示されます。",
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return const StepGuidePage(
      title: "ポイントとトークンの使い方",
      intro: "このアプリの開発者が作ったゲームで貯めたポイントは、トークンに交換できます。\n"
          "トークンは、AIが日記を書くときに使う、使用量の単位です。\n"
          "アカウントがなくても、アプリは、毎月の無料枠の中で使えます。",
      steps: _steps,
    );
  }
}
