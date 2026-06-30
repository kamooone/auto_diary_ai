import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/ogp_fetcher.dart';
import '../../data/repositories/share_repository_impl.dart';
import '../../domain/repositories/share_repository.dart';
import '../../domain/usecases/share_tweet_usecase.dart';
import '../../domain/usecases/save_shared_post_usecase.dart';
import '../../application/share_service.dart';


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
    ref.read(ogpFetcherProvider),
  );
});

// --------------------
// UseCase（取得）
// --------------------
final shareTweetUseCaseProvider = Provider<ShareTweetUseCase>((ref) {
  return ShareTweetUseCase(ref.read(ogpFetcherProvider));
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
// Service
// --------------------
final shareServiceProvider = Provider<ShareService>((ref) {
  return ShareService(
    ref.read(shareTweetUseCaseProvider),
    ref.read(saveSharedPostUseCaseProvider),
  );
});