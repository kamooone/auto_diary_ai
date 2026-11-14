import 'package:flutter/material.dart';

import '../../../../core/widgets/step_guide.dart';

/// Xのアーカイブを入手して、このアプリに取り込むまでの流れ
/// (「Xのアーカイブを取り込む」の画面の右上から開く)
class XArchiveGuidePage extends StatelessWidget {
  const XArchiveGuidePage({super.key});

  static const _steps = [
    GuideStep(
      title: "Xで、アーカイブをリクエストする",
      body: "Xの「設定とプライバシー」から、「アカウント」の中の「データのアーカイブをダウンロード」を開きます。\n"
          "本人確認をして、アーカイブをリクエストします。",
    ),
    GuideStep(
      title: "用意ができるのを待つ",
      body: "アーカイブの用意には、1日以上かかることがあります。\n"
          "用意ができると、Xから通知やメールが届きます。",
    ),
    GuideStep(
      title: "アーカイブをダウンロードする",
      body: "同じ画面から、アーカイブ(ZIPファイル)をダウンロードします。\n"
          "投稿が多いと、ファイルが大きくなります。通信量や、空き容量に気をつけてください。",
    ),
    GuideStep(
      title: "ZIPファイルを開く",
      body: "ダウンロードしたZIPファイルを、端末のファイルのアプリなどで、解凍します。\n"
          "中の「data」フォルダに、「tweets.js」があります。",
    ),
    GuideStep(
      title: "このアプリで、tweets.js を選ぶ",
      body: "「Xのアーカイブを取り込む」の画面で、「tweets.js を選ぶ」を押して、解凍した「tweets.js」を選びます。\n"
          "ほかのファイルは、使いません。",
    ),
    GuideStep(
      title: "取り込む年を選ぶ",
      body: "見つかった投稿の件数が、年ごとに表示されます。\n"
          "取り込む年を選んで、「取り込む」を押します。\n"
          "同じ投稿は、何度取り込んでも増えません。",
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return const StepGuidePage(
      title: "アーカイブの取り込み方",
      intro: "Xでは、過去の投稿をまとめたファイル(アーカイブ)をダウンロードできます。\n"
          "それをこのアプリに取り込むと、過去の投稿を、日記の材料にできます。",
      steps: _steps,
      note: "Xの画面の名前や手順は、変わることがあります。",
    );
  }
}
