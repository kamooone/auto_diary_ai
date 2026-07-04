import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import '../../../map/application/providers/location_providers.dart';
import '../../../share/application/providers/share_service_provider.dart';
import '../../application/providers/diary_usecase_providers.dart';

class DiaryCreateState {
  final String title;
  final String content;
  final String generatedDiary;
  final bool isLoading;
  final DateTime selectedDate;

  DiaryCreateState({
    this.title = '',
    this.content = '',
    this.generatedDiary = '',
    this.isLoading = false,
    required this.selectedDate,
  });

  DiaryCreateState copyWith({
    String? title,
    String? content,
    String? generatedDiary,
    bool? isLoading,
    DateTime? selectedDate,
  }) {
    return DiaryCreateState(
      title: title ?? this.title,
      content: content ?? this.content,
      generatedDiary: generatedDiary ?? this.generatedDiary,
      isLoading: isLoading ?? this.isLoading,
      selectedDate: selectedDate ?? this.selectedDate,
    );
  }
}

class DiaryCreateViewModel extends Notifier<DiaryCreateState> {
  late final _generateDiaryUseCase = ref.read(generateDiaryUseCaseProvider);
  late final _getTodayPhotosUseCase = ref.read(getTodayPhotosUseCaseProvider);

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

  Future<void> generateDiary() async {

    state = state.copyWith(isLoading: true);

    try {
      // 今日の写真を取得
      final photos = await _getTodayPhotosUseCase.execute(state.selectedDate);

      // 本日の行動履歴を取得
      late final getLocationsByDateUseCase = ref.read(getLocationsByDateUseCaseProvider);
      final locations = await getLocationsByDateUseCase.execute(
        state.selectedDate,
      );

      // 本日のXのポスト一覧を取得
      late final shareService = ref.read(shareServiceProvider);
      final posts = await shareService.getPosts(
        state.selectedDate,
      );

      // AIに日記を書いてもらう処理を呼び出し
      final result = await _generateDiaryUseCase.execute(
        title: state.title,
        content: state.content,
        date: state.selectedDate,
        photos: photos,
        locations: locations,
        posts: posts,
      );

      state = state.copyWith(
        generatedDiary: result,
        isLoading: false,
      );
    } catch (e, stackTrace) {
      debugPrint(e.toString());
      debugPrintStack(stackTrace: stackTrace);

      state = state.copyWith(
        isLoading: false,
        generatedDiary: "生成に失敗しました",
      );
    }
  }

  Future<void> pickPhoto() async {
    state = state.copyWith(isLoading: true);

    try {
      final photos =
      await _getTodayPhotosUseCase.execute(state.selectedDate);

      debugPrint('今日の写真数: ${photos.length}');

      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false);
    }
  }
}