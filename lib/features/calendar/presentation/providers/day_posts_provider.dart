import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../share/application/providers/share_providers.dart';
import '../../../share/domain/entities/shared_post.dart';

// 指定した日の投稿一覧
final dayPostsProvider =
FutureProvider.autoDispose.family<List<SharedPost>, DateTime>((ref, date) {
  return ref.watch(getSharedPostsUseCaseProvider).execute(date);
});
