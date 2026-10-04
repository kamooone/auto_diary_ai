import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/photo_repository_impl.dart';
import '../../domain/repositories/photo_repository.dart';
import '../../domain/usecases/generate_diary_usecase.dart';
import '../../domain/usecases/get_photo_thumbnail_usecase.dart';
import '../../domain/usecases/get_photos_usecase.dart';
import '../../../ai/application/providers/ai_provider.dart';
import '../../../location/application/providers/location_providers.dart';

// Repository
final photoRepositoryProvider = Provider<PhotoRepository>((ref) {
  return PhotoRepositoryImpl();
});

// UseCase
final generateDiaryUseCaseProvider = Provider<GenerateDiaryUseCase>((ref) {
  return GenerateDiaryUseCase(
    ref.read(sendMessageUseCaseProvider),
    ref.read(photoRepositoryProvider),
    ref.read(placeNameRepositoryProvider),
  );
});

final getPhotosUseCaseProvider = Provider<GetPhotosUseCase>((ref) {
  return GetPhotosUseCase(
    ref.read(photoRepositoryProvider),
  );
});

final getPhotoThumbnailUseCaseProvider =
    Provider<GetPhotoThumbnailUseCase>((ref) {
  return GetPhotoThumbnailUseCase(
    ref.read(photoRepositoryProvider),
  );
});
