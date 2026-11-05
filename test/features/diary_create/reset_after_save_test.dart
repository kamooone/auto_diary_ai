import 'package:auto_diary_ai/features/diary_create/application/providers/diary_usecase_providers.dart';
import 'package:auto_diary_ai/features/diary_create/domain/entities/diary_style.dart';
import 'package:auto_diary_ai/features/diary_create/domain/entities/summary_style.dart';
import 'package:auto_diary_ai/features/diary_create/domain/repositories/diary_style_repository.dart';
import 'package:auto_diary_ai/features/diary_create/domain/repositories/summary_style_repository.dart';
import 'package:auto_diary_ai/features/diary_create/presentation/providers/diary_create_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeDiaryStyleRepository implements DiaryStyleRepository {
  DiaryStyle saved = DiaryStyle.diary;

  @override
  Future<DiaryStyle> load() async => saved;

  @override
  Future<void> save(DiaryStyle style) async => saved = style;
}

class _FakeSummaryStyleRepository implements SummaryStyleRepository {
  SummaryStyle saved = SummaryStyle.reading;

  @override
  Future<SummaryStyle> load() async => saved;

  @override
  Future<void> save(SummaryStyle style) async => saved = style;
}

void main() {
  test('保存後のリセットのあとも、あとの読み込みや生成の結果が反映される', () async {
    final diaryRepo = _FakeDiaryStyleRepository();
    final summaryRepo = _FakeSummaryStyleRepository();
    final container = ProviderContainer(
      overrides: [
        diaryStyleRepositoryProvider.overrideWithValue(diaryRepo),
        summaryStyleRepositoryProvider.overrideWithValue(summaryRepo),
      ],
    );
    addTearDown(container.dispose);

    // 画面が見ている間は、破棄されない(本物の画面と同じ)
    container.listen(diaryCreateProvider, (_, __) {});

    final notifier = container.read(diaryCreateProvider.notifier);
    notifier.setDiaryStyle(DiaryStyle.custom);
    expect(diaryRepo.saved, DiaryStyle.custom);

    notifier.resetAfterSave();

    // 書き方が、初期値に戻る
    expect(container.read(diaryCreateProvider).diaryStyle, DiaryStyle.diary);
    expect(diaryRepo.saved, DiaryStyle.diary);
    expect(summaryRepo.saved, SummaryStyle.reading);

    // リセット後も、非同期の結果が捨てられない(捨てられると、書いている表示が終わらない)
    diaryRepo.saved = DiaryStyle.values.last;
    await container.read(diaryCreateProvider.notifier).loadDiaryStyle();
    expect(
      container.read(diaryCreateProvider).diaryStyle,
      DiaryStyle.values.last,
    );
  });
}
