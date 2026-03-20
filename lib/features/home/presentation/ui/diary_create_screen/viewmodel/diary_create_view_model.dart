import 'package:flutter_riverpod/flutter_riverpod.dart';

final diaryCreateProvider = NotifierProvider<DiaryCreateViewModel, DiaryCreateState>(
  DiaryCreateViewModel.new,
);

class DiaryCreateState {
  final String inputText;
  final String generatedDiary;
  final bool isLoading;

  const DiaryCreateState({
    this.inputText = '',
    this.generatedDiary = '',
    this.isLoading = false,
  });

  DiaryCreateState copyWith({
    String? inputText,
    String? generatedDiary,
    bool? isLoading,
  }) {
    return DiaryCreateState(
      inputText: inputText ?? this.inputText,
      generatedDiary: generatedDiary ?? this.generatedDiary,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class DiaryCreateViewModel extends Notifier<DiaryCreateState> {
  @override
  DiaryCreateState build() => const DiaryCreateState();

  void setInputTitle(String text) {
    state = state.copyWith(inputText: text);
  }

  void setMainContent(String text) {
    state = state.copyWith(inputText: text);
  }

  Future<void> generateDiary() async {
    if (state.inputText.isEmpty) return;

    state = state.copyWith(isLoading: true);

    // TODO: AI API呼び出し
    await Future.delayed(const Duration(seconds: 2));
    final generated = "AIが作った日記: ${state.inputText}";

    state = state.copyWith(generatedDiary: generated, isLoading: false);
  }
}
