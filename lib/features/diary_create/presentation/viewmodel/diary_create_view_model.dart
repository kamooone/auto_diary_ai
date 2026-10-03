import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import 'package:photo_manager/photo_manager.dart';
import '../../../ai/domain/exceptions/ai_exception.dart';
import '../../../map/application/providers/location_providers.dart';
import '../../../share/application/providers/share_service_provider.dart';
import '../../application/providers/diary_usecase_providers.dart';

class DiaryCreateState {
  final String title;
  final String content;
  final String generatedDiary;
  final bool isLoading;
  final DateTime selectedDate;
  final List<AssetEntity> selectedPhotos;

  DiaryCreateState({
    this.title = '',
    this.content = '',
    this.generatedDiary = '',
    this.isLoading = false,
    required this.selectedDate,
    this.selectedPhotos = const [],
  });

  DiaryCreateState copyWith({
    String? title,
    String? content,
    String? generatedDiary,
    bool? isLoading,
    DateTime? selectedDate,
    List<AssetEntity>? selectedPhotos,
  }) {
    return DiaryCreateState(
      title: title ?? this.title,
      content: content ?? this.content,
      generatedDiary: generatedDiary ?? this.generatedDiary,
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
  void setSelectedPhotos(List<AssetEntity> photos) {
    state = state.copyWith(selectedPhotos: List.unmodifiable(photos));
  }

  void removeSelectedPhoto(AssetEntity photo) {
    state = state.copyWith(
      selectedPhotos: List.unmodifiable(
        state.selectedPhotos.where((e) => e.id != photo.id),
      ),
    );
  }

  Future<void> generateDiary() async {

    state = state.copyWith(isLoading: true);

    try {
      // ユーザーが選択した写真を使用
      final photos = state.selectedPhotos;

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
    } on AiUploadException catch (e, stackTrace) {
      debugPrint(e.toString());
      debugPrintStack(stackTrace: stackTrace);

      state = state.copyWith(
        isLoading: false,
        generatedDiary: "写真のアップロードに失敗しました",
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
}
