import 'package:auto_diary_ai/features/diary_create/presentation/ui/diary_ai_screen.dart';
import 'package:auto_diary_ai/features/location/application/providers/location_providers.dart';
import 'package:auto_diary_ai/features/location/domain/entities/timeline_item.dart';
import 'package:auto_diary_ai/features/location/domain/usecases/get_timeline_by_date_usecase.dart';
import 'package:auto_diary_ai/features/memo/application/providers/memo_providers.dart';
import 'package:auto_diary_ai/features/memo/domain/entities/memo.dart';
import 'package:auto_diary_ai/features/memo/domain/repositories/memo_repository.dart';
import 'package:auto_diary_ai/features/plan/domain/repositories/plan_repository.dart';
import 'package:auto_diary_ai/features/share/application/providers/share_providers.dart';
import 'package:auto_diary_ai/features/share/domain/entities/shared_post.dart';
import 'package:auto_diary_ai/features/share/domain/usecases/get_shared_posts_usecase.dart';
import 'package:auto_diary_ai/features/plan/application/providers/plan_provider.dart';
import 'package:auto_diary_ai/features/plan/domain/entities/plan_type.dart';
import 'package:auto_diary_ai/features/plan/domain/entities/usage_info.dart';
import 'package:auto_diary_ai/features/plan/domain/repositories/usage_repository.dart';
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

class _FakeUsage implements UsageRepository {
  @override
  Future<UsageInfo?> fetch({PlanType plan = PlanType.free}) async =>
      const UsageInfo(usedTokens: 0, limitTokens: 100000);
}

class _FakePlan implements PlanRepository {
  @override
  Future<PlanType> load() async => PlanType.free;

  @override
  Future<void> save(PlanType plan) async {}
}

class _FakeTimeline implements GetTimelineByDateUseCase {
  @override
  Future<List<TimelineItem>> execute(
    DateTime date, {
    bool estimatePlaces = true,
  }) async => [];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakePosts implements GetSharedPostsUseCase {
  @override
  Future<List<SharedPost>> execute(DateTime date) async => [];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeMemos implements MemoRepository {
  @override
  Future<List<Memo>> findBetween(DateTime start, DateTime end) async => [];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets('AIに日記を書いてもらう画面は、初めて表示したときだけ、チュートリアルを最後まで出す', (tester) async {
    final store = _FakeStore();

    // ふつうのスマホの大きさ(360x780)にする
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    Future<void> open() async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            tutorialSeenStoreProvider.overrideWithValue(store),
            usageRepositoryProvider.overrideWithValue(_FakeUsage()),
            planRepositoryProvider.overrideWithValue(_FakePlan()),
            getTimelineByDateUseCaseProvider.overrideWithValue(_FakeTimeline()),
            getSharedPostsUseCaseProvider.overrideWithValue(_FakePosts()),
            memoRepositoryProvider.overrideWithValue(_FakeMemos()),
          ],
          child: const MaterialApp(home: DiaryAiScreen()),
        ),
      );
      await tester.pumpAndSettle();
    }

    await open();

    expect(find.text('日記の日付'), findsWidgets);
    expect(find.text('1 / 10'), findsOneWidget);

    // 最後の「完了」まで、「次へ」で進める(下にある部品も、スクロールして見せる)
    for (var i = 0; i < 9; i++) {
      await tester.tap(find.text('次へ'));
      await tester.pumpAndSettle();
    }
    expect(find.text('日記を書いてもらう'), findsWidgets);
    expect(find.text('10 / 10'), findsOneWidget);

    await tester.tap(find.text('完了'));
    await tester.pumpAndSettle();

    expect(store.seen, {'diary_ai'});

    // 見たあとは、開き直しても出ない
    await open();
    expect(find.text('1 / 10'), findsNothing);
  });
}
