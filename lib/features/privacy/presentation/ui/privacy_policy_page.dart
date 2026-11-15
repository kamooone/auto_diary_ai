import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// プライバシーポリシーの画面
///
/// 文章は `assets/privacy_policy.md` から読む(ストアに出すWebページも、同じファイルを元にする)。
/// 使うMarkdownは、`# ` 大見出し、`## ` 見出し、`- ` 箇条書き、`**太字**`、空行で区切った段落だけ。
class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key, this.loader});

  /// 文章の読み込み(テストで差し替える)
  final Future<String> Function()? loader;

  static const assetPath = 'assets/privacy_policy.md';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('プライバシーポリシー')),
      body: FutureBuilder<String>(
        future: (loader ?? () => rootBundle.loadString(assetPath))(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('読み込めませんでした'));
          }
          final text = snapshot.data;
          if (text == null) {
            return const Center(child: CircularProgressIndicator());
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: _blocks(context, text),
          );
        },
      ),
    );
  }

  static List<Widget> _blocks(BuildContext context, String source) {
    final theme = Theme.of(context);
    final widgets = <Widget>[];

    for (final raw in source.split('\n')) {
      final line = raw.trimRight();
      if (line.isEmpty) continue;

      if (line.startsWith('## ')) {
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(top: 20, bottom: 6),
            child: Text(line.substring(3), style: theme.textTheme.titleMedium),
          ),
        );
      } else if (line.startsWith('# ')) {
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(line.substring(2), style: theme.textTheme.titleLarge),
          ),
        );
      } else if (line.startsWith('- ')) {
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(left: 8, bottom: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('・'),
                Expanded(child: _rich(line.substring(2), theme)),
              ],
            ),
          ),
        );
      } else {
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: _rich(line, theme),
          ),
        );
      }
    }
    return widgets;
  }

  /// `**太字**` だけを、太字にする
  static Widget _rich(String line, ThemeData theme) {
    final style = theme.textTheme.bodyMedium;
    final spans = <TextSpan>[];
    final parts = line.split('**');
    for (var i = 0; i < parts.length; i++) {
      if (parts[i].isEmpty) continue;
      spans.add(
        TextSpan(
          text: parts[i],
          style: i.isOdd ? const TextStyle(fontWeight: FontWeight.bold) : null,
        ),
      );
    }
    return Text.rich(TextSpan(style: style, children: spans));
  }
}
