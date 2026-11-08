import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/database/isar_provider.dart';
import '../../data/repositories/diary_repository_impl.dart';
import '../../domain/entities/diary.dart';
import '../../domain/repositories/diary_repository.dart';
import '../../domain/usecases/delete_diary_usecase.dart';
import '../../domain/usecases/save_diary_usecase.dart';
import '../../domain/usecases/watch_diaries_usecase.dart';

// Repository
final diaryRepositoryProvider = Provider<DiaryRepository>((ref) {
  return DiaryRepositoryImpl(
    ref.watch(isarProvider),
  );
});

// UseCase
final saveDiaryUseCaseProvider = Provider<SaveDiaryUseCase>((ref) {
  return SaveDiaryUseCase(
    ref.watch(diaryRepositoryProvider),
  );
});

final deleteDiaryUseCaseProvider = Provider<DeleteDiaryUseCase>((ref) {
  return DeleteDiaryUseCase(
    ref.watch(diaryRepositoryProvider),
  );
});

final watchDiariesUseCaseProvider = Provider<WatchDiariesUseCase>((ref) {
  return WatchDiariesUseCase(
    ref.watch(diaryRepositoryProvider),
  );
});

// 保存されている日記(新しい日付順)。保存・削除のたびに更新される
final diariesProvider = StreamProvider<List<Diary>>((ref) {
  return ref.watch(watchDiariesUseCaseProvider).execute();
});
