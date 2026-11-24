import 'package:flutter/material.dart';

import '../data/tutorial_seen_store.dart';
import '../domain/tutorial_step.dart';
import 'tutorial_runner.dart';

/// 右上に「?」アイコンがある画面の、初めて表示したときだけのチュートリアル
///
/// 「?」に気づかない利用者が多いため、次の2ページで、「?」の場所を、はっきり知らせる。
///   1. その画面の簡単な説明
///   2. 「?」アイコンを明るくして、くわしくは、そこで確認できること
///
/// 見終わったら、見たことを覚えて、次からは出さない([tutorialId]が、覚えるときの名前)
Future<void> showHelpIconTutorialOnce(
  BuildContext context, {
  required TutorialSeenStore store,
  required String tutorialId,
  required String screenTitle,
  required String screenBody,
  required GlobalKey helpKey,
  required String helpBody,
}) async {
  if (await store.hasSeen(tutorialId)) return;
  if (!context.mounted) return;

  await showTutorial(context, [
    TutorialStep.intro(title: screenTitle, body: screenBody),
    TutorialStep(
      target: helpKey,
      title: '使い方は「?」で確認できます',
      body: helpBody,
      circle: true,
    ),
  ]);

  await store.markSeen(tutorialId);
}
