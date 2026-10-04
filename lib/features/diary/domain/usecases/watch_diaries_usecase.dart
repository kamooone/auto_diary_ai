import '../entities/diary.dart';
import '../repositories/diary_repository.dart';

class WatchDiariesUseCase {
  final DiaryRepository repository;

  WatchDiariesUseCase(this.repository);

  Stream<List<Diary>> execute() {
    return repository.watchAll();
  }
}
