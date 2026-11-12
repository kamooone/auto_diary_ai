import 'package:auto_diary_ai/features/tutorial/domain/tutorial_step.dart';
import 'package:auto_diary_ai/features/tutorial/presentation/tutorial_runner.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('次へ・戻るで読み進め、最後の完了で終わる(スキップはない)', (tester) async {
    final a = GlobalKey();
    final b = GlobalKey();
    var finished = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              Container(key: a, width: 80, height: 40, color: Colors.red),
              Container(key: b, width: 80, height: 40, color: Colors.blue),
              Builder(
                builder: (context) => TextButton(
                  onPressed: () async {
                    await showTutorial(context, [
                      TutorialStep(target: a, title: '一つ目', body: '説明A'),
                      TutorialStep(target: b, title: '二つ目', body: '説明B'),
                    ]);
                    finished = true;
                  },
                  child: const Text('開始'),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    await tester.tap(find.text('開始'));
    await tester.pumpAndSettle();

    expect(find.text('一つ目'), findsOneWidget);
    expect(find.text('1 / 2'), findsOneWidget);
    expect(find.text('戻る'), findsNothing);
    expect(find.text('スキップ'), findsNothing);
    expect(find.text('Skip'), findsNothing);

    await tester.tap(find.text('次へ'));
    await tester.pumpAndSettle();

    expect(find.text('二つ目'), findsOneWidget);
    expect(find.text('完了'), findsOneWidget);

    await tester.tap(find.text('戻る'));
    await tester.pumpAndSettle();
    expect(find.text('一つ目'), findsOneWidget);

    await tester.tap(find.text('次へ'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('完了'));
    await tester.pumpAndSettle();

    expect(finished, isTrue);
    expect(find.text('二つ目'), findsNothing);
  });

  testWidgets('部品を指さない紹介のステップも、1ページとして出せる', (tester) async {
    final a = GlobalKey();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              Container(key: a, width: 80, height: 40, color: Colors.red),
              Builder(
                builder: (context) => TextButton(
                  onPressed: () => showTutorial(context, [
                    const TutorialStep.intro(title: '紹介', body: 'こんなアプリです'),
                    TutorialStep(target: a, title: '部品', body: '説明'),
                  ]),
                  child: const Text('開始'),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    await tester.tap(find.text('開始'));
    await tester.pumpAndSettle();

    expect(find.text('紹介'), findsOneWidget);
    expect(find.text('こんなアプリです'), findsOneWidget);
    expect(find.text('1 / 2'), findsOneWidget);

    await tester.tap(find.text('次へ'));
    await tester.pumpAndSettle();
    expect(find.text('部品'), findsOneWidget);
  });
}
