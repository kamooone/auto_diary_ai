import 'package:isar/isar.dart';
import '../../domain/entities/diary.dart';
import '../../domain/repositories/diary_repository.dart';
import '../models/diary_log.dart';

class DiaryRepositoryImpl implements DiaryRepository {
  final Isar isar;

  DiaryRepositoryImpl(this.isar);

  @override
  Future<void> save(Diary diary) async {
    final log = DiaryLog()
      ..date = diary.date
      ..title = diary.title
      ..content = diary.content
      ..isAiGenerated = diary.isAiGenerated
      ..photoIds = diary.photoIds
      ..createdAt = diary.createdAt;

    final id = diary.id;
    if (id != null) {
      log.id = id;
    }

    await isar.writeTxn(() async {
      await isar.diaryLogs.put(log);
    });
  }

  @override
  Future<void> delete(int id) async {
    await isar.writeTxn(() async {
      await isar.diaryLogs.delete(id);
    });
  }

  @override
  Stream<List<Diary>> watchAll() {
    return isar.diaryLogs
        .where()
        .sortByDateDesc()
        .thenByCreatedAtDesc()
        .watch(fireImmediately: true)
        .map((logs) => logs.map(_toEntity).toList());
  }

  Diary _toEntity(DiaryLog log) {
    return Diary(
      id: log.id,
      date: log.date,
      title: log.title,
      content: log.content,
      isAiGenerated: log.isAiGenerated,
      photoIds: log.photoIds,
      createdAt: log.createdAt,
    );
  }
}
