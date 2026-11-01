import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import '../../data/repositories/file_summary_style_repository.dart';
import '../../domain/repositories/summary_style_repository.dart';
import '../../domain/usecases/consult_summary_usecase.dart';
import '../../data/repositories/photo_repository_impl.dart';
import '../../domain/repositories/photo_repository.dart';
import '../../domain/entities/diary_plan.dart';
import '../../domain/usecases/generate_diary_usecase.dart';
import '../../domain/usecases/generate_summary_diary_usecase.dart';
import '../../domain/usecases/get_photo_thumbnail_usecase.dart';
import '../../domain/usecases/get_photos_usecase.dart';
import '../../../ai/application/providers/ai_provider.dart';
import '../../../plan/application/providers/plan_provider.dart';

// 日記作成の制限(ユーザーのプランに応じた値)
final diaryPlanProvider = Provider<DiaryPlan>((ref) {
  return DiaryPlan.forType(ref.watch(planTypeProvider));
});

// Repository
final photoRepositoryProvider = Provider<PhotoRepository>((ref) {
  return PhotoRepositoryImpl();
});

final summaryStyleRepositoryProvider = Provider<SummaryStyleRepository>((ref) {
  return FileSummaryStyleRepository(() async {
    final dir = await getApplicationSupportDirectory();
    return File('${dir.path}/summary_style.json');
  });
});

// UseCase
final consultSummaryUseCaseProvider = Provider<ConsultSummaryUseCase>((ref) {
  return ConsultSummaryUseCase(aiRepository: ref.watch(aiRepositoryProvider));
});

final generateDiaryUseCaseProvider = Provider<GenerateDiaryUseCase>((ref) {
  return GenerateDiaryUseCase(
    aiRepository: ref.watch(aiRepositoryProvider),
    photoRepository: ref.watch(photoRepositoryProvider),
  );
});

final generateSummaryDiaryUseCaseProvider =
    Provider<GenerateSummaryDiaryUseCase>((ref) {
  return GenerateSummaryDiaryUseCase(
    aiRepository: ref.watch(aiRepositoryProvider),
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
