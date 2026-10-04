import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/database/isar_provider.dart';
import '../../data/datasources/ogp_fetcher.dart';
import '../../data/repositories/share_repository_impl.dart';
import '../../domain/repositories/share_repository.dart';
import '../../domain/usecases/get_shared_posts_usecase.dart';
import '../../domain/usecases/save_shared_post_usecase.dart';
import '../../domain/usecases/share_tweet_usecase.dart';

// --------------------
// DataSource
// --------------------
final ogpFetcherProvider = Provider<OgpFetcher>((ref) {
  return OgpFetcher();
});

// --------------------
// Repository
// --------------------
final shareRepositoryProvider = Provider<ShareRepository>((ref) {
  return ShareRepositoryImpl(
    ref.watch(ogpFetcherProvider),
    ref.watch(isarProvider),
  );
});

// --------------------
// UseCase（取得）
// --------------------
final shareTweetUseCaseProvider = Provider<ShareTweetUseCase>((ref) {
  return ShareTweetUseCase(
    ref.watch(shareRepositoryProvider),
  );
});

// --------------------
// UseCase（保存）
// --------------------
final saveSharedPostUseCaseProvider =
Provider<SaveSharedPostUseCase>((ref) {
  return SaveSharedPostUseCase(
    ref.watch(shareRepositoryProvider),
  );
});

// --------------------
// UseCase（isarから取得）
// --------------------
final getSharedPostsUseCaseProvider =
Provider<GetSharedPostsUseCase>((ref) {
  return GetSharedPostsUseCase(
    ref.watch(shareRepositoryProvider),
  );
});
