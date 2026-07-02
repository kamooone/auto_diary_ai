import 'package:auto_diary_ai/features/share/domain/usecases/get_shared_posts_use_case.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/providers/data_provider.dart';
import '../usecases/share_tweet_usecase.dart';
import '../usecases/save_shared_post_usecase.dart';

// --------------------
// UseCase（取得）
// --------------------
final shareTweetUseCaseProvider = Provider<ShareTweetUseCase>((ref) {
  return ShareTweetUseCase(
    ref.read(ogpFetcherProvider),
  );
});

// --------------------
// UseCase（保存）
// --------------------
final saveSharedPostUseCaseProvider =
Provider<SaveSharedPostUseCase>((ref) {
  return SaveSharedPostUseCase(
    ref.read(shareRepositoryProvider),
  );
});

// --------------------
// UseCase（isarから取得）
// --------------------
final getSharedPostsUseCaseProvider =
Provider<GetSharedPostsUseCase>((ref) {
  return GetSharedPostsUseCase(
    ref.read(shareRepositoryProvider),
  );
});