import 'package:flutter/material.dart';

import '../../../../core/widgets/step_guide.dart';

/// ポイントを貯めて、トークンに交換し、このアプリで使うまでの流れ
/// (「ポイント・トークン」の画面の右上から開く)
class PointsGuidePage extends StatelessWidget {
  const PointsGuidePage({super.key});

  static const _steps = [
    GuideStep(
      title: "Webで、アカウントを作る",
      body: "「Webを開く」から、Webのページを開いて、アカウントを作ります。\n"
          "アカウントの作成は、Webで行います。",
    ),
    GuideStep(
      title: "Webのゲームで、ポイントを貯める",
      body: "Webのページに、ポイントを貯められるゲームのリンクがあります。\n"
          "ゲームで遊ぶと、ポイントが貯まります。",
    ),
    GuideStep(
      title: "Webで、ポイントをトークンに交換する",
      body: "貯めたポイントは、Webで、トークンに交換します。\n"
          "トークンがあると、AIに日記を書いてもらえる量が増えます。",
    ),
    GuideStep(
      title: "このアプリで、コードを発行する",
      body: "このアプリの「ポイント・トークン」の画面で、「コードを発行する」を押します。\n"
          "6桁のコードが表示されます。有効期限は10分です。",
    ),
    GuideStep(
      title: "Webで、コードを入力して紐づける",
      body: "Webにログインして、コードを入力します。\n"
          "確認の画面で、この端末であることを確かめて、紐づけます。\n"
          "自分で発行したコード以外は、入力しないでください。",
    ),
    GuideStep(
      title: "トークンが使えるようになる",
      body: "紐づけると、この画面に、トークンの残高が表示されます。\n"
          "毎月の枠を使い切ったあとに、残高から使われます。",
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return const StepGuidePage(
      title: "ポイントとトークンの使い方",
      intro: "ポイントを貯めて、トークンに交換すると、AIに日記を書いてもらえる量が増えます。\n"
          "アカウントがなくても、アプリは、毎月の枠の中で使えます。",
      steps: _steps,
    );
  }
}
