import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/providers/usecase_provider.dart';
import '../share_service.dart';


final shareServiceProvider = Provider<ShareService>((ref) {
  return ShareService(
    ref.read(shareTweetUseCaseProvider),
    ref.read(saveSharedPostUseCaseProvider),
    ref.read(getSharedPostsUseCaseProvider),
  );
});
