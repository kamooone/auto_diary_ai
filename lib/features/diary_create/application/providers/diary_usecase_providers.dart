import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/photo_repository_impl.dart';
import '../../domain/repositories/photo_repository.dart';
import '../../domain/entities/diary_plan.dart';
import '../../domain/usecases/generate_diary_usecase.dart';
import '../../domain/usecases/get_photo_thumbnail_usecase.dart';
import '../../domain/usecases/get_photos_usecase.dart';
import '../../../ai/application/providers/ai_provider.dart';
import '../../../location/application/providers/location_providers.dart';

// 日記作成の制限
// 課金機能を追加するときは、ここでユーザーのプランに応じた値を返す
final diaryPlanProvider = Provider<DiaryPlan>((ref) {
  return DiaryPlan.free;
});

// Repository
final photoRepositoryProvider = Provider<PhotoRepository>((ref) {
  return PhotoRepositoryImpl();
});

// UseCase
final generateDiaryUseCaseProvider = Provider<GenerateDiaryUseCase>((ref) {
  return GenerateDiaryUseCase(
    aiRepository: ref.watch(aiRepositoryProvider),
    photoRepository: ref.watch(photoRepositoryProvider),
    placeNameRepository: ref.watch(placeNameRepositoryProvider),
  );
});

final getPhotosUseCaseProvider = Provider<GetPhotosUseCase>((ref) {
  return GetPhotosUseCase(
    ref.watch(photoRepositoryProvider),
  );
});

final getPhotoThumbnailUseCaseProvider =
    Provider<GetPhotoThumbnailUseCase>((ref) {
  return GetPhotoThumbnailUseCase(
    ref.watch(photoRepositoryProvider),
  );
});
