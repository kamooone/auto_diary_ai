import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/database/isar_provider.dart';
import '../../data/repositories/memo_repository_impl.dart';
import '../../domain/entities/memo.dart';
import '../../domain/repositories/memo_repository.dart';

final memoRepositoryProvider = Provider<MemoRepository>((ref) {
  return MemoRepositoryImpl(ref.watch(isarProvider));
});

/// 保存したすべてのメモ(新しい順)
/// 追加・修正・削除したあとは、ref.invalidate で読み込み直す
final allMemosProvider = FutureProvider.autoDispose<List<Memo>>((ref) {
  return ref.watch(memoRepositoryProvider).findAll();
});
