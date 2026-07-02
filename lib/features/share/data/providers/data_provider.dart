import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/database/isar_provider.dart';
import '../datasources/ogp_fetcher.dart';
import '../repositories/share_repository_impl.dart';
import '../../domain/repositories/share_repository.dart';

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
    ref.read(isarProvider),
  );
});