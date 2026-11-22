import 'package:flutter/material.dart';

import '../../../../core/widgets/step_guide.dart';

/// ポイントを貯めて、トークンに交換し、このアプリで使うまでの流れ
/// (「ポイント・ゲーム」の画面の右上から開く)
class PointsGuidePage extends StatelessWidget {
  const PointsGuidePage({super.key});

  static const _steps = [
    GuideStep(
      title: "ポイントのページで、アカウントを作る",
      body: "「ポイントのページを開く」を押すと、ポイントのページが開きます。\n"
          "そこで、アカウントを作成します。",
    ),
    GuideStep(
      title: "ゲームで、ポイントを貯める",
      body: "このアプリの開発者が作ったゲームで、同じアカウントと紐づけて遊ぶと、"
          "ポイントが貯まります。\n"
          "ゲームの一覧は、ポイントのページに載っています。",
    ),
    GuideStep(
      title: "ポイントを、トークンに交換する",
      body: "貯めたポイントは、ポイントのページで、トークンに交換できます。",
    ),
    GuideStep(
      title: "アプリで、コードを発行する",
      body: "このアプリの「ポイント・ゲーム」の画面で、「コードを発行する」を押すと、"
          "6桁のコードが表示されます。\n"
          "コードの有効期限は、10分です。",
    ),
    GuideStep(
      title: "ポイントのページで、コードを入力する",
      body: "ポイントのページにログインして、コードを入力すると、このアプリとアカウントが紐づけされます。",
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
      intro: "ゲームで遊ぶとポイントが貯まります。\n"
          "貯めたポイントは、AIが日記を書くときに使う「トークン」に交換できます。\n"
          "ポイントを貯めるには、アカウントが必要です。",
      steps: _steps,
    );
  }
}
