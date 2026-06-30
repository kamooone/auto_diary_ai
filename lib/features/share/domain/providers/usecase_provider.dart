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