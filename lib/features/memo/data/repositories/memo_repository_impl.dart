import 'package:isar/isar.dart';
import '../../domain/entities/memo.dart';
import '../../domain/repositories/memo_repository.dart';
import '../models/memo_model.dart';

class MemoRepositoryImpl implements MemoRepository {
  final Isar isar;

  MemoRepositoryImpl(this.isar);

  @override
  Future<void> save(Memo memo) async {
    await isar.writeTxn(() async {
      await isar.memoModels.put(_toModel(memo, id: Isar.autoIncrement));
    });
  }

  @override
  Future<void> update(Memo memo) async {
    final id = memo.id;
    if (id == null) throw ArgumentError('idのないメモは更新できません');

    await isar.writeTxn(() async {
      await isar.memoModels.put(_toModel(memo, id: id));
    });
  }

  @override
  Future<void> delete(int id) async {
    await isar.writeTxn(() async {
      await isar.memoModels.delete(id);
    });
  }

  @override
  Future<List<Memo>> findAll() async {
    final models = await isar.memoModels.where().sortByCreatedAtDesc().findAll();

    return models.map(_toMemo).toList();
  }

  @override
  Future<List<Memo>> findBetween(DateTime start, DateTime end) async {
    final models = await isar.memoModels
        .filter()
        .createdAtBetween(start, end, includeUpper: false)
        .sortByCreatedAt()
        .findAll();

    return models.map(_toMemo).toList();
  }

  MemoModel _toModel(Memo memo, {required int id}) {
    return MemoModel()
      ..id = id
      ..text = memo.text
      ..createdAt = memo.createdAt
      ..photoIds = memo.photoIds;
  }

  Memo _toMemo(MemoModel model) {
    return Memo(
      id: model.id,
      text: model.text,
      createdAt: model.createdAt,
      photoIds: model.photoIds,
    );
  }
}
