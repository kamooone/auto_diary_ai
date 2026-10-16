import 'dart:async';
import 'package:auto_diary_ai/features/diary_create/presentation/providers/diary_create_provider.dart';
import 'package:auto_diary_ai/features/location/application/providers/location_providers.dart';
import 'package:auto_diary_ai/features/location/domain/entities/timeline_item.dart';
import 'package:auto_diary_ai/features/location/domain/usecases/get_timeline_by_date_usecase.dart';
import 'package:auto_diary_ai/features/plan/application/providers/plan_provider.dart';
import 'package:auto_diary_ai/features/plan/domain/entities/plan_type.dart';
import 'package:auto_diary_ai/features/plan/domain/repositories/plan_repository.dart';
import 'package:auto_diary_ai/features/share/application/providers/share_providers.dart';
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
    expect(state.selectedTimeline, hasLength(1));
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
}
