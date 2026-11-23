import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../common/constants/app_colors.dart';
import '../../../../common/constants/app_sizes.dart';
import '../../../../common/widgets/app_card.dart';

/// プライバシーポリシーの画面
///
/// 文章は `assets/privacy_policy.md` から読む(ストアに出すWebページも、同じファイルを元にする)。
/// 使うMarkdownは、`# ` 大見出し、`## ` 見出し、`- ` 箇条書き、`**太字**`、空行で区切った段落だけ。
///
/// [title]と[assetPath]を渡すと、同じ作りで、別の文書(利用規約など)も出せる。
class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({
    super.key,
    this.loader,
    this.title = 'プライバシーポリシー',
    this.assetPath = defaultAssetPath,
  });

  /// 文章の読み込み(テストで差し替える)
  final Future<String> Function()? loader;

  /// 画面の題
  final String title;

  /// 読み込む文章のファイル
  final String assetPath;

  static const defaultAssetPath = 'assets/privacy_policy.md';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
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
          // 本文の全体を、1枚のカードに入れる
          return ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSizes.space16,
              20,
              AppSizes.space16,
              AppSizes.space24,
            ),
            children: [
              AppCard(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: _blocks(context, text),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  static const _bodyStyle = TextStyle(
    fontSize: 14,
    height: 1.9,
    color: AppColors.text,
  );

  static List<Widget> _blocks(BuildContext context, String source) {
    final widgets = <Widget>[];

    // 「最終改定日」があるときは、その下に線を引く(制定日の下には引かない)
    final hasRevisedDate = source.contains('最終改定日');

    for (final raw in source.split('\n')) {
      final line = raw.trimRight();
      if (line.isEmpty) continue;

      if (line.startsWith('## ')) {
        // 見出し
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(top: 24, bottom: AppSizes.space8),
            child: Text(
              line.substring(3),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.navyDark,
              ),
            ),
          ),
        );
      } else if (line.startsWith('# ')) {
        // タイトル
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(bottom: AppSizes.space4),
            child: Text(
              line.substring(2),
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: AppColors.text,
              ),
            ),
          ),
        );
      } else if (line.startsWith('制定日') || line.startsWith('最終改定日')) {
        // 制定日・最終改定日(小さく出す)。最後の日付の下に、線を引く
        widgets.add(
          Text(
            line,
            style: const TextStyle(fontSize: 12, color: AppColors.textSub),
          ),
        );
        final isLast = line.startsWith('最終改定日') || !hasRevisedDate;
        if (isLast) {
          widgets.add(
            const Padding(
              padding: EdgeInsets.symmetric(vertical: AppSizes.space16),
              child: Divider(height: 1, thickness: 1, color: AppColors.line),
            ),
          );
        }
      } else if (line.startsWith('- ')) {
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(left: 20, bottom: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('・', style: _bodyStyle),
                Expanded(child: _rich(line.substring(2))),
              ],
            ),
          ),
        );
      } else {
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: _rich(line),
          ),
        );
      }
    }
    return widgets;
  }

  /// `**太字**` だけを、太字にする
  static Widget _rich(String line) {
    const style = _bodyStyle;
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
