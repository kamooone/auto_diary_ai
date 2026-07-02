import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/usecases/generate_diary_usecase.dart';
import '../../domain/usecases/get_today_photos_usecase.dart';
import '../../../ai/application/providers/ai_provider.dart';

final generateDiaryUseCaseProvider =
Provider<GenerateDiaryUseCase>((ref) {
  return GenerateDiaryUseCase(
    ref.read(sendMessageUseCaseProvider),
  );
});

final getTodayPhotosUseCaseProvider =
Provider<GetTodayPhotosUseCase>((ref) {
  return GetTodayPhotosUseCase();
});