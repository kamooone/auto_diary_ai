import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import '../../../ai/domain/exceptions/ai_exception.dart';
import '../../application/providers/diary_usecase_providers.dart';
import '../../domain/entities/photo.dart';

class DiaryCreateState {
  final String title;
  final String content;
  final String generatedDiary;
  final String? errorMessage;
  final bool isLoading;
  final DateTime selectedDate;
  final List<Photo> selectedPhotos;

  DiaryCreateState({
    this.title = '',
    this.content = '',
    this.generatedDiary = '',
    this.errorMessage,
    this.isLoading = false,
    required this.selectedDate,
    this.selectedPhotos = const [],
  });

  DiaryCreateState copyWith({
    String? title,
    String? content,
    String? generatedDiary,
    String? errorMessage,
    bool clearError = false,
    bool? isLoading,
    DateTime? selectedDate,
    List<Photo>? selectedPhotos,
  }) {
    return DiaryCreateState(
      title: title ?? this.title,
      content: content ?? this.content,
      generatedDiary: generatedDiary ?? this.generatedDiary,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      isLoading: isLoading ?? this.isLoading,
      selectedDate: selectedDate ?? this.selectedDate,
      selectedPhotos: selectedPhotos ?? this.selectedPhotos,
    );
  }
}

class DiaryCreateViewModel extends Notifier<DiaryCreateState> {
  late final _generateDiaryUseCase = ref.read(generateDiaryUseCaseProvider);

  @override
  DiaryCreateState build() {
    final now = DateTime.now();
    return DiaryCreateState(
      selectedDate: DateTime(now.year, now.month, now.day),
    );
  }

  void setSelectedDate(DateTime date) {
    state = state.copyWith(selectedDate: date);
  }

  void setInputTitle(String text) {
    state = state.copyWith(title: text);
  }

  void setMainContent(String text) {
    state = state.copyWith(content: text);
  }

  // ユーザーが選択した写真をセット
  void setSelectedPhotos(List<Photo> photos) {
    state = state.copyWith(selectedPhotos: List.unmodifiable(photos));
  }

  void removeSelectedPhoto(Photo photo) {
    state = state.copyWith(
      selectedPhotos: List.unmodifiable(
        state.selectedPhotos.where((e) => e.id != photo.id),
      ),
    );
  }

  Future<void> generateDiary() async {

    state = state.copyWith(isLoading: true, clearError: true);

    try {
      // AIに日記を書いてもらう処理を呼び出し
      final result = await _generateDiaryUseCase.execute(
        title: state.title,
        content: state.content,
        date: state.selectedDate,
        photos: state.selectedPhotos,
      );

      state = state.copyWith(
        generatedDiary: result,
        isLoading: false,
      );
    } on AiUploadException catch (e, stackTrace) {
      debugPrint(e.toString());
      debugPrintStack(stackTrace: stackTrace);

      state = state.copyWith(
        isLoading: false,
        errorMessage: "写真のアップロードに失敗しました",
      );
    } catch (e, stackTrace) {
      debugPrint(e.toString());
      debugPrintStack(stackTrace: stackTrace);

      state = state.copyWith(
        isLoading: false,
        errorMessage: "生成に失敗しました",
      );
    }
  }
}
