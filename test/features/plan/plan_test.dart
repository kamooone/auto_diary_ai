import 'dart:io';
import 'package:auto_diary_ai/features/diary_create/application/providers/diary_usecase_providers.dart';
import 'package:auto_diary_ai/features/diary_create/domain/entities/diary_plan.dart';
import 'package:auto_diary_ai/features/diary_create/presentation/providers/diary_create_provider.dart';
import 'package:auto_diary_ai/features/diary_create/presentation/ui/widgets/diary_period_text.dart';
import 'package:auto_diary_ai/features/plan/application/providers/plan_provider.dart';
import 'package:auto_diary_ai/features/plan/data/file_plan_repository.dart';
import 'package:auto_diary_ai/features/plan/domain/entities/plan_type.dart';
import 'package:auto_diary_ai/features/plan/domain/repositories/plan_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class InMemoryPlanRepository implements PlanRepository {
  PlanType plan = PlanType.free;

  @override
  Future<PlanType> load() async => plan;

  @override
  Future<void> save(PlanType plan) async => this.plan = plan;
}

void main() {
  group('DiaryPlan', () {
    test('無料プランは選んだ1日分だけ、有料プランは複数日分を扱える', () {
      expect(DiaryPlan.free.maxDays, 1);
      expect(DiaryPlan.free.allowsMultipleDays, isFalse);

      expect(DiaryPlan.paid.maxDays, greaterThan(1));
      expect(DiaryPlan.paid.allowsMultipleDays, isTrue);
    });

    test('プランの種類から制限を取り出せる', () {
      expect(DiaryPlan.forType(PlanType.free), DiaryPlan.free);
      expect(DiaryPlan.forType(PlanType.paid), DiaryPlan.paid);
    });
  });

  group('FilePlanRepository', () {
    late Directory dir;
    late FilePlanRepository repository;

    setUp(() {
      dir = Directory.systemTemp.createTempSync('plan_test');
      repository = FilePlanRepository(
        () async => File('${dir.path}/sub/plan.json'),
      );
    });

    tearDown(() => dir.deleteSync(recursive: true));

    test('保存されていない場合は無料プラン', () async {
      expect(await repository.load(), PlanType.free);
    });

    test('保存したプランを読み出せる', () async {
      await repository.save(PlanType.paid);
      expect(await repository.load(), PlanType.paid);

      await repository.save(PlanType.free);
      expect(await repository.load(), PlanType.free);
    });

    test('ファイルが壊れていたり、未知のプランだった場合は無料プラン', () async {
      final file = File('${dir.path}/sub/plan.json')
        ..createSync(recursive: true);

      file.writeAsStringSync('not json');
      expect(await repository.load(), PlanType.free);

      file.writeAsStringSync('{"plan":"platinum"}');
      expect(await repository.load(), PlanType.free);
    });
  });

  group('プランの切り替えと日記の対象期間', () {
    late InMemoryPlanRepository repository;
    late ProviderContainer container;

    setUp(() {
      repository = InMemoryPlanRepository();
      container = ProviderContainer(
        overrides: [planRepositoryProvider.overrideWithValue(repository)],
      );
      addTearDown(container.dispose);
    });

    test('保存してあるプランを、起動時に読み込む', () async {
      repository.plan = PlanType.paid;

      expect(container.read(planTypeProvider), PlanType.free);
      await Future<void>.delayed(Duration.zero);

      expect(container.read(planTypeProvider), PlanType.paid);
      expect(container.read(diaryPlanProvider), DiaryPlan.paid);
    });

    test('プランを切り替えると、保存して制限も変わる', () async {
      await container.read(planTypeProvider.notifier).setPlan(PlanType.paid);

      expect(repository.plan, PlanType.paid);
      expect(container.read(diaryPlanProvider).allowsMultipleDays, isTrue);
    });

    test('読み込みが終わる前に切り替えても、遅れて届いた読み込み結果で戻らない', () async {
      repository.plan = PlanType.free;

      container.read(planTypeProvider);
      await container.read(planTypeProvider.notifier).setPlan(PlanType.paid);
      await Future<void>.delayed(Duration.zero);

      expect(container.read(planTypeProvider), PlanType.paid);
    });

    test('無料プランでは、複数日を選んでも開始日の1日分になる', () {
      final viewModel = container.read(diaryCreateProvider.notifier);
      container.listen(diaryCreateProvider, (_, __) {});

      viewModel.setDateRange(DateTime(2026, 1, 1), DateTime(2026, 1, 5));

      final state = container.read(diaryCreateProvider);
      expect(state.startDate, DateTime(2026, 1, 1));
      expect(state.endDate, DateTime(2026, 1, 1));
    });

    test('有料プランでは、選べる日数までの期間を選べる', () async {
      await container.read(planTypeProvider.notifier).setPlan(PlanType.paid);
      container.listen(diaryCreateProvider, (_, __) {});
      final viewModel = container.read(diaryCreateProvider.notifier);

      viewModel.setDateRange(DateTime(2026, 1, 1), DateTime(2026, 1, 3));
      expect(container.read(diaryCreateProvider).endDate, DateTime(2026, 1, 3));

      // 選べる日数を超えた分は切り捨てる
      viewModel.setDateRange(DateTime(2026, 1, 1), DateTime(2026, 2, 28));
      expect(
        container.read(diaryCreateProvider).endDate,
        DateTime(2026, 1, DiaryPlan.paid.maxDays),
      );

      // 終了日が開始日より前の場合は、開始日の1日分にする
      viewModel.setDateRange(DateTime(2026, 1, 5), DateTime(2026, 1, 2));
      expect(container.read(diaryCreateProvider).endDate, DateTime(2026, 1, 5));
    });

    test('期間を変えると、AIに渡す選択内容を空に戻す', () async {
      await container.read(planTypeProvider.notifier).setPlan(PlanType.paid);
      container.listen(diaryCreateProvider, (_, __) {});
      final viewModel = container.read(diaryCreateProvider.notifier);

      viewModel.setSelectedPosts(const []);
      viewModel.setDateRange(DateTime(2026, 1, 1), DateTime(2026, 1, 2));

      final state = container.read(diaryCreateProvider);
      expect(state.aiPhotos, isEmpty);
      expect(state.selectedTimeline, isEmpty);
    });
  });

  test('対象期間の表示', () {
    expect(
      DiaryPeriodText.format(DateTime(2026, 1, 1), DateTime(2026, 1, 1)),
      '2026年1月1日',
    );
    expect(
      DiaryPeriodText.format(DateTime(2026, 1, 1), DateTime(2026, 1, 3)),
      '2026年1月1日〜1月3日（3日間）',
    );
    expect(
      DiaryPeriodText.format(DateTime(2025, 12, 30), DateTime(2026, 1, 2)),
      '2025年12月30日〜2026年1月2日（4日間）',
    );
  });
}
