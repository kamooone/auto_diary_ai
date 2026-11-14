import 'package:flutter/material.dart';

/// Xの投稿を、このアプリに共有して保存するまでの流れ(「Xの投稿」の画面の右上から開く)
class XShareGuidePage extends StatelessWidget {
  const XShareGuidePage({super.key});

  static const _steps = [
    _Step(
      title: "Xのアプリで、保存したい投稿を開く",
      body: "日記の材料にしたい投稿を、Xのアプリで表示します。",
    ),
    _Step(
      title: "投稿の「共有」ボタンを押す",
      body: "投稿の下にある、次のような形のボタンを押します。",
      // Xの共有ボタンに近い、四角から上向きの矢印が出る形
      icon: Icons.ios_share,
    ),
    _Step(
      title: "共有先の一覧から、このアプリを選ぶ",
      body: "共有先の一覧から、「あなたの軌跡」を選びます。\n"
          "一覧に見つからないときは、「もっと見る」などで、アプリの一覧を広げてください。",
    ),
    _Step(
      title: "投稿の内容を確認する",
      body: "このアプリが開いて、「投稿内容の確認」が表示されます。\n"
          "投稿の本文が合っているかを確認します。",
    ),
    _Step(
      title: "日時を選ぶ",
      body: "「日時を選択」を押して、この投稿を、いつのこととして保存するかを選びます。\n"
          "日記を作成するときは、選んだ日時の投稿として使われます。",
    ),
    _Step(
      title: "OKを押して保存する",
      body: "保存した投稿は、この「Xの投稿」の画面に表示されます。\n"
          "ここから、削除や、内容の修正、日時の変更ができます。",
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Xから共有する方法")),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            "Xの投稿を、このアプリに保存して、日記の材料にできます。",
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 16),
          for (var i = 0; i < _steps.length; i++)
            _StepTile(number: i + 1, step: _steps[i]),
        ],
      ),
    );
  }
}

class _Step {
  const _Step({required this.title, required this.body, this.icon});

  final String title;
  final String body;

  /// 手順の中で、押すボタンの見た目を見せるアイコン
  final IconData? icon;
}

class _StepTile extends StatelessWidget {
  const _StepTile({required this.number, required this.step});

  final int number;
  final _Step step;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: theme.colorScheme.primary,
            foregroundColor: theme.colorScheme.onPrimary,
            child: Text("$number", style: theme.textTheme.labelLarge),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(step.title, style: theme.textTheme.titleMedium),
                const SizedBox(height: 4),
                Text(step.body, style: theme.textTheme.bodyMedium),
                if (step.icon != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: theme.dividerColor),
                    ),
                    child: Icon(step.icon, size: 28),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
