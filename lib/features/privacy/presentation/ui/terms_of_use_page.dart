import 'package:flutter/material.dart';

import 'privacy_policy_page.dart';

/// 利用規約の画面
///
/// 文章は `assets/terms_of_use.md` から読む(Webページも、同じファイルを元にする)。
/// 作りは、プライバシーポリシーの画面と同じ。
class TermsOfUsePage extends StatelessWidget {
  const TermsOfUsePage({super.key, this.loader});

  /// 文章の読み込み(テストで差し替える)
  final Future<String> Function()? loader;

  static const assetPath = 'assets/terms_of_use.md';

  @override
  Widget build(BuildContext context) {
    return PrivacyPolicyPage(
      title: '利用規約',
      assetPath: assetPath,
      loader: loader,
    );
  }
}
