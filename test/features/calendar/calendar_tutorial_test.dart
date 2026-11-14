import 'package:auto_diary_ai/features/calendar/presentation/ui/calendar_screen.dart';
import 'package:auto_diary_ai/features/diary/application/providers/diary_providers.dart';
import 'package:auto_diary_ai/features/diary/domain/entities/diary.dart';
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
}

void main() {
  testWidgets('カレンダー画面は、初めて表示したときだけ、1ページのチュートリアルを出す', (tester) async {
    final store = _FakeStore();

    Future<void> open() async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            tutorialSeenStoreProvider.overrideWithValue(store),
            diariesProvider.overrideWith(
              (ref) => Stream.value(const <Diary>[]),
            ),
          ],
          child: const MaterialApp(home: CalendarScreen()),
        ),
      );
      await tester.pumpAndSettle();
    }

    await open();

    expect(find.text('1 / 1'), findsOneWidget);
    expect(find.textContaining('月を切り替えられます'), findsOneWidget);

    await tester.tap(find.text('完了'));
    await tester.pumpAndSettle();

    expect(store.seen, {'calendar'});

    // 見たあとは、開き直しても出ない
    await open();
    expect(find.text('1 / 1'), findsNothing);
  });
}
