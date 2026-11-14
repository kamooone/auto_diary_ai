import 'package:auto_diary_ai/features/diary_create/presentation/ui/diary_create_screen.dart';
import 'package:auto_diary_ai/features/tutorial/application/tutorial_providers.dart';
import 'package:auto_diary_ai/features/tutorial/data/tutorial_seen_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeStore implements TutorialSeenStore {
  final seen = <String>{};

  @override
  Future<bool> hasSeen(String id) async => seen.contains(id);

  @override
  Future<void> markSeen(String id) async => seen.add(id);

  @override
  Future<void> clearAll() async => seen.clear();
}

void main() {
  testWidgets('日記作成画面は、初めて表示したときだけ、チュートリアルを最後まで出す', (tester) async {
    final store = _FakeStore();

    Future<void> open() async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [tutorialSeenStoreProvider.overrideWithValue(store)],
          child: const MaterialApp(home: DiaryCreateScreen()),
        ),
      );
      await tester.pumpAndSettle();
    }

    await open();

    expect(find.text('自分で日記を書く'), findsWidgets);
    expect(find.text('1 / 3'), findsOneWidget);

    // 最後の「完了」まで、「次へ」で進める(下にある部品も、スクロールして見せる)
    for (var i = 0; i < 2; i++) {
      await tester.tap(find.text('次へ'));
      await tester.pumpAndSettle();
    }
    expect(find.text('振り返りを作成する'), findsWidgets);
    expect(find.text('3 / 3'), findsOneWidget);

    await tester.tap(find.text('完了'));
    await tester.pumpAndSettle();

    expect(store.seen, {'diary_create'});

    // 見たあとは、開き直しても出ない
    await open();
    expect(find.text('1 / 3'), findsNothing);
  });
}
