import 'dart:async';

import 'package:flutter/material.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';

import '../domain/tutorial_step.dart';

/// スポットライト式のチュートリアルを出して、最後まで見終わったら完了する
///
/// 画面を暗くして、[TutorialStep.target]の部品だけを明るくし、そばに吹き出しを出す。
/// 「次へ」(最後は「完了」)と「戻る」で、ページをめくるように読み進める。スキップはない。
Future<void> showTutorial(BuildContext context, List<TutorialStep> steps) {
  final done = Completer<void>();
  final last = steps.length - 1;
  final screen = MediaQuery.sizeOf(context);

  final targets = [
    for (var i = 0; i < steps.length; i++)
      TargetFocus(
        identify: 'step$i',
        keyTarget: steps[i].target,
        // 部品を指さないステップは、画面の中央の小さな点を指して、吹き出しを中ほどに出す
        targetPosition: steps[i].target == null
            ? TargetPosition(const Size(1, 1), screen.center(Offset.zero))
            : null,
        shape: steps[i].circle ? ShapeLightFocus.Circle : ShapeLightFocus.RRect,
        radius: 12,
        // 「次へ」の操作だけで進める(暗い部分や、明るい部分をタップしても進まない)
        enableOverlayTab: false,
        enableTargetTab: false,
        contents: [
          TargetContent(
            align: steps[i].target == null
                ? ContentAlign.custom
                : steps[i].bubbleAbove
                ? ContentAlign.top
                : ContentAlign.bottom,
            customPosition: steps[i].target == null
                ? CustomTargetContentPosition(
                    top: screen.height * 0.28,
                    left: 16,
                    right: 16,
                  )
                : null,
            builder: (context, controller) => TutorialBubble(
              title: steps[i].title,
              body: steps[i].body,
              page: i + 1,
              pageCount: steps.length,
              isFirst: i == 0,
              isLast: i == last,
              onPrevious: controller.previous,
              onNext: controller.next,
            ),
          ),
        ],
      ),
  ];

  TutorialCoachMark(
    targets: targets,
    colorShadow: Colors.black,
    opacityShadow: 0.8,
    paddingFocus: 6,
    hideSkip: true,
    disableBackButton: true,
    // 画面を縦にスクロールできるときは、部品が見える位置まで動かしてから明るくする
    // (吹き出しを出す側に余白ができるよう、上に出すときは下寄り、下に出すときは上寄りに置く)
    beforeFocus: (target) async {
      final index = targets.indexOf(target);
      final key = index < 0 ? null : steps[index].target;
      final targetContext = key?.currentContext;
      if (targetContext == null || !targetContext.mounted) return;

      await Scrollable.ensureVisible(
        targetContext,
        alignment: steps[index].bubbleAbove ? 0.75 : 0.25,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    },
    pulseEnable: false,
    onFinish: () {
      if (!done.isCompleted) done.complete();
    },
  ).show(context: context);

  return done.future;
}

/// チュートリアルの吹き出し(白い角丸の枠に、タイトル・説明・ページ送りのボタン)
class TutorialBubble extends StatelessWidget {
  const TutorialBubble({
    super.key,
    required this.title,
    required this.body,
    required this.page,
    required this.pageCount,
    required this.isFirst,
    required this.isLast,
    required this.onPrevious,
    required this.onNext,
  });

  final String title;
  final String body;
  final int page;
  final int pageCount;
  final bool isFirst;
  final bool isLast;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: DefaultTextStyle(
        style: const TextStyle(
          color: Colors.black87,
          fontSize: 14,
          height: 1.5,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                color: primary,
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(body),
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  '$page / $pageCount',
                  style: const TextStyle(color: Colors.black45, fontSize: 12),
                ),
                const Spacer(),
                if (!isFirst)
                  TextButton(onPressed: onPrevious, child: const Text('戻る')),
                FilledButton(
                  onPressed: onNext,
                  child: Text(isLast ? '完了' : '次へ'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
