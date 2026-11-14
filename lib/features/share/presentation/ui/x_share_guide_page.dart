import 'package:flutter/material.dart';

import '../../../../core/widgets/step_guide.dart';

/// Xの投稿を、このアプリに共有して保存するまでの流れ(「Xの投稿一覧」の画面の右上から開く)
class XShareGuidePage extends StatelessWidget {
  const XShareGuidePage({super.key});

  static const _steps = [
    GuideStep(
      title: "Xのアプリで、保存したい投稿を開く",
      body: "日記の材料にしたい投稿を、Xのアプリで表示します。",
    ),
    GuideStep(
      title: "投稿の「共有」ボタンを押す",
      body: "投稿の下に並ぶボタンの、いちばん右にある、次のような形のボタンを押します。",
      // Xのアプリの共有ボタン(3つの点がつながった形)
      icon: Icons.share,
    ),
    GuideStep(
      title: "共有先の一覧から、このアプリを選ぶ",
      body: "共有先の一覧から、「あなたの軌跡」を選びます。\n"
          "一覧に見つからないときは、「もっと見る」などで、アプリの一覧を広げてください。",
    ),
    GuideStep(
      title: "投稿の内容を確認する",
      body: "このアプリが開いて、「投稿内容の確認」が表示されます。\n"
          "投稿の本文が合っているかを確認します。",
    ),
    GuideStep(
      title: "日時を選ぶ",
      body: "「日時を選択」を押して、この投稿を、いつのこととして保存するかを選びます。\n"
          "日記を作成するときは、選んだ日時の投稿として使われます。",
    ),
    GuideStep(
      title: "OKを押して保存する",
      body: "保存した投稿は、この「Xの投稿一覧」の画面に表示されます。\n"
          "ここから、削除や、内容の修正、日時の変更ができます。",
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return const StepGuidePage(
      title: "Xから共有する方法",
      intro: "Xの投稿を、このアプリに保存して、日記の材料にできます。",
      steps: _steps,
    );
  }
}
