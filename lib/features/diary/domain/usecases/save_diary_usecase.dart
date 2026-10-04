import '../entities/diary.dart';
import '../repositories/diary_repository.dart';

class SaveDiaryUseCase {
  final DiaryRepository repository;

  SaveDiaryUseCase(this.repository);

  Future<void> execute(Diary diary) {
    return repository.save(diary);
  }
}
