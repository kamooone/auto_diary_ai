import '../repositories/diary_repository.dart';

class DeleteDiaryUseCase {
  final DiaryRepository repository;

  DeleteDiaryUseCase(this.repository);

  Future<void> execute(int id) {
    return repository.delete(id);
  }
}
