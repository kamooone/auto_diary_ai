import '../entities/diary.dart';

abstract class DiaryRepository {
  Future<void> save(Diary diary);

  Future<void> delete(int id);

  /// 保存されている日記(新しい日付順)。変更があるたびに最新の一覧が流れる
  Stream<List<Diary>> watchAll();
}
