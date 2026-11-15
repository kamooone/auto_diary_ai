import 'dart:async';
import 'package:auto_diary_ai/features/diary_create/presentation/providers/diary_create_provider.dart';
import 'package:auto_diary_ai/features/location/application/providers/location_providers.dart';
import 'package:auto_diary_ai/features/location/domain/entities/timeline_item.dart';
import 'package:auto_diary_ai/features/location/domain/usecases/get_timeline_by_date_usecase.dart';
import 'package:auto_diary_ai/features/plan/application/providers/plan_provider.dart';
import 'package:auto_diary_ai/features/plan/domain/entities/plan_type.dart';
import 'package:auto_diary_ai/features/plan/domain/repositories/plan_repository.dart';
import 'package:auto_diary_ai/features/share/application/providers/share_providers.dart';
import 'package:auto_diary_ai/features/x_archive/application/providers/x_archive_providers.dart';
import 'package:auto_diary_ai/features/x_archive/domain/entities/x_archive_post.dart';
import '../x_archive/fake_x_archive_repository.dart';
import 'package:auto_diary_ai/features/share/domain/entities/shared_post.dart';
import 'package:auto_diary_ai/features/share/domain/usecases/get_shared_posts_usecase.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class InMemoryPlanRepository implements PlanRepository {
  @override
  Future<PlanType> load() async => PlanType.free;

  @override
  Future<void> save(PlanType plan) async {}
}

/// 日ごとに、その日に1つだけ滞在がある行動履歴を返す
class FakeGetTimeline implements GetTimelineByDateUseCase {
  final requestedDays = <DateTime>[];

  /// 指定した日の読み込みが終わるのを、止めておく
  final holds = <DateTime, Completer<void>>{};

  @override
  Future<List<TimelineItem>> execute(
    DateTime date, {
    bool estimatePlaces = true,
  }) async {
    requestedDays.add(date);
    await holds[date]?.future;

    return [
      Stay(
        start: date.add(const Duration(hours: 9)),
        end: date.add(const Duration(hours: 10)),
        latitude: 35.0,
        longitude: 139.0,
      ),
    ];
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeGetSharedPosts implements GetSharedPostsUseCase {
  @override
  Future<List<SharedPost>> execute(DateTime date) async => [];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late FakeGetTimeline timeline;
  late ProviderContainer container;

  setUp(() {
    timeline = FakeGetTimeline();
    container = ProviderContainer(
      overrides: [
        planRepositoryProvider.overrideWithValue(InMemoryPlanRepository()),
        getTimelineByDateUseCaseProvider.overrideWithValue(timeline),
        getSharedPostsUseCaseProvider.overrideWithValue(FakeGetSharedPosts()),
      ],
    );
    container.listen(diaryCreateProvider, (_, __) {});
    addTearDown(container.dispose);
  });

  test('日記の日付を昨日以前に変えて読み込み直すと、その日の行動履歴が出る', () async {
    final viewModel = container.read(diaryCreateProvider.notifier);

    await viewModel.loadSources();

    // 日付を変えると、AIに渡せる情報は空に戻る(読み込み直すまで)
    viewModel.setDate(DateTime(2026, 1, 5));
    expect(container.read(diaryCreateProvider).timeline, isEmpty);

    await viewModel.loadSources();

    final state = container.read(diaryCreateProvider);
    expect(state.timeline, hasLength(1));
    expect(state.timeline.single.start, DateTime(2026, 1, 5, 9));
    // 読み込んだ直後は、すべて未選択
    expect(state.selectedTimeline, isEmpty);
    expect(state.selectedPosts, isEmpty);
  });

  test('有料プランで日記の日付と違う期間を選んでも、読み込みは終わり、期間の行動履歴が出る', () async {
    await container.read(planTypeProvider.notifier).setPlan(PlanType.paid);
    final viewModel = container.read(diaryCreateProvider.notifier);

    viewModel.setDate(DateTime(2026, 1, 10));
    viewModel.setAiDateRange(DateTime(2026, 1, 1), DateTime(2026, 1, 3));

    // 日記の日付と期間が違っていても、読み込みを繰り返し続けない
    await viewModel.loadSources().timeout(const Duration(seconds: 5));

    final state = container.read(diaryCreateProvider);
    expect(state.isLoadingSources, isFalse);
    expect(state.timeline.map((e) => e.start.day), [1, 2, 3]);
    expect(timeline.requestedDays, hasLength(3));
  });

  test('読み込み中に日付を変えた場合は、古い日の結果を反映せず、新しい日を読み込む', () async {
    final viewModel = container.read(diaryCreateProvider.notifier);

    viewModel.setDate(DateTime(2026, 1, 5));

    // 1月5日の読み込みを、止めておく
    final hold = timeline.holds[DateTime(2026, 1, 5)] = Completer<void>();
    final loading = viewModel.loadSources();

    // その間に、1月6日に変える
    viewModel.setDate(DateTime(2026, 1, 6));
    hold.complete();
    await loading;
    await viewModel.loadSources();

    final state = container.read(diaryCreateProvider);
    expect(state.timeline.single.start, DateTime(2026, 1, 6, 9));
  });

  test('取り込んだXの投稿も、期間のものが、日本時間の日付で出る(リツイートは出ない)', () async {
    XArchivePost post(String id, DateTime utc, XArchivePostKind kind) =>
        XArchivePost(tweetId: id, text: 'text$id', createdAt: utc, kind: kind);

    final archive = FakeXArchiveRepository([
      // 日本時間 2026/1/2 08:00
      post('1', DateTime.utc(2026, 1, 1, 23), XArchivePostKind.post),
      // 日本時間 2026/1/3 00:30(期間の最終日)
      post('2', DateTime.utc(2026, 1, 2, 15, 30), XArchivePostKind.reply),
      // 期間より前(日本時間 2025/12/31 23:00)
      post('3', DateTime.utc(2025, 12, 31, 14), XArchivePostKind.post),
      // 期間より後(日本時間 2026/1/4 00:00)
      post('4', DateTime.utc(2026, 1, 3, 15), XArchivePostKind.post),
      // リツイートは、日記の材料にしない
      post('5', DateTime.utc(2026, 1, 2, 1), XArchivePostKind.retweet),
    ]);
    final c = ProviderContainer(
      overrides: [
        planRepositoryProvider.overrideWithValue(InMemoryPlanRepository()),
        getTimelineByDateUseCaseProvider.overrideWithValue(FakeGetTimeline()),
        getSharedPostsUseCaseProvider.overrideWithValue(FakeGetSharedPosts()),
        xArchiveRepositoryProvider.overrideWithValue(archive),
      ],
    );
    addTearDown(c.dispose);
    c.listen(diaryCreateProvider, (_, __) {});

    final viewModel = c.read(diaryCreateProvider.notifier);
    viewModel.setDate(DateTime(2026, 1, 3));
    viewModel.setAiDateRange(DateTime(2026, 1, 1), DateTime(2026, 1, 3));
    await viewModel.loadSources();

    final posts = c.read(diaryCreateProvider).posts;
    expect(posts.map((e) => e.text), ['text1', 'text2']);
    expect(posts.first.receivedAt, DateTime(2026, 1, 2, 8));
    expect(posts.last.receivedAt, DateTime(2026, 1, 3, 0, 30));
  });
}
