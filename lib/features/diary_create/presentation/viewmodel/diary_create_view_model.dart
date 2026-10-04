import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import '../../../ai/domain/exceptions/ai_exception.dart';
import '../../../location/application/providers/location_providers.dart';
import '../../../location/domain/entities/timeline_item.dart';
import '../../../share/application/providers/share_providers.dart';
import '../../../share/domain/entities/shared_post.dart';
import '../../application/providers/diary_usecase_providers.dart';
import '../../domain/entities/photo.dart';

class DiaryCreateState {
  final String title;
  final String content;
  final String generatedDiary;
  final String? errorMessage;
  final bool isLoading;

  /// 日記の対象期間(1日分の場合は同じ日)
  final DateTime startDate;
  final DateTime endDate;

  /// AIに渡す写真
  final List<Photo> selectedPhotos;

  /// 対象期間のXの投稿と、そのうちAIに渡すもの
  final List<SharedPost> posts;
  final List<SharedPost> selectedPosts;

  /// 対象期間の行動履歴(滞在と移動)と、そのうちAIに渡すもの
  final List<TimelineItem> timeline;
  final List<TimelineItem> selectedTimeline;

  /// Xの投稿と行動履歴を読み込み中かどうか
  final bool isLoadingSources;

  DiaryCreateState({
    this.title = '',
    this.content = '',
    this.generatedDiary = '',
    this.errorMessage,
    this.isLoading = false,
    required this.startDate,
    required this.endDate,
    this.selectedPhotos = const [],
    this.posts = const [],
    this.selectedPosts = const [],
    this.timeline = const [],
    this.selectedTimeline = const [],
    this.isLoadingSources = false,
  });

  DiaryCreateState copyWith({
    String? title,
    String? content,
    String? generatedDiary,
    String? errorMessage,
    bool clearError = false,
    bool? isLoading,
    DateTime? startDate,
    DateTime? endDate,
    List<Photo>? selectedPhotos,
    List<SharedPost>? posts,
    List<SharedPost>? selectedPosts,
    List<TimelineItem>? timeline,
    List<TimelineItem>? selectedTimeline,
    bool? isLoadingSources,
  }) {
    return DiaryCreateState(
      title: title ?? this.title,
      content: content ?? this.content,
      generatedDiary: generatedDiary ?? this.generatedDiary,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      isLoading: isLoading ?? this.isLoading,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      selectedPhotos: selectedPhotos ?? this.selectedPhotos,
      posts: posts ?? this.posts,
      selectedPosts: selectedPosts ?? this.selectedPosts,
      timeline: timeline ?? this.timeline,
      selectedTimeline: selectedTimeline ?? this.selectedTimeline,
      isLoadingSources: isLoadingSources ?? this.isLoadingSources,
    );
  }
}

class DiaryCreateViewModel extends AutoDisposeNotifier<DiaryCreateState> {
  late final _generateDiaryUseCase = ref.read(generateDiaryUseCaseProvider);

  // 画面を閉じた後に読み込みや生成が終わった場合、結果を反映しないようにする
  bool _isDisposed = false;

  @override
  DiaryCreateState build() {
    ref.onDispose(() => _isDisposed = true);

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // 初期表示は今日の日記。Xの投稿と行動履歴を読み込む
    Future.microtask(_loadSources);

    return DiaryCreateState(
      startDate: today,
      endDate: today,
      isLoadingSources: true,
    );
  }

  /// 日記の対象日を変更する
  /// 対象日が変わると選べる情報も変わるため、選択内容は読み込み直す
  void setDate(DateTime date) {
    final day = DateTime(date.year, date.month, date.day);

    state = state.copyWith(
      startDate: day,
      endDate: day,
      selectedPhotos: const [],
      posts: const [],
      selectedPosts: const [],
      timeline: const [],
      selectedTimeline: const [],
      isLoadingSources: true,
    );

    _loadSources();
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

  // AIに渡すXの投稿をセット
  void setSelectedPosts(List<SharedPost> posts) {
    state = state.copyWith(selectedPosts: List.unmodifiable(posts));
  }

  // AIに渡す行動履歴をセット
  void setSelectedTimeline(List<TimelineItem> items) {
    state = state.copyWith(selectedTimeline: List.unmodifiable(items));
  }

  /// 対象期間のXの投稿と行動履歴を読み込む(最初はすべて選択済みにする)
  Future<void> _loadSources() async {
    final start = state.startDate;
    final end = state.endDate;

    final posts = <SharedPost>[];
    final timeline = <TimelineItem>[];

    try {
      final getSharedPosts = ref.read(getSharedPostsUseCaseProvider);
      final getTimeline = ref.read(getTimelineByDateUseCaseProvider);

      for (var day = start;
          !day.isAfter(end);
          day = DateTime(day.year, day.month, day.day + 1)) {
        posts.addAll(await getSharedPosts.execute(day));
        timeline.addAll(await getTimeline.execute(day));
      }

      posts.sort((a, b) => a.receivedAt.compareTo(b.receivedAt));
    } catch (e, stackTrace) {
      debugPrint(e.toString());
      debugPrintStack(stackTrace: stackTrace);
    }

    if (_isDisposed) return;

    // 読み込み中に対象日が変更された場合は反映しない
    if (state.startDate != start || state.endDate != end) {
      return;
    }

    state = state.copyWith(
      posts: List.unmodifiable(posts),
      selectedPosts: List.unmodifiable(posts),
      timeline: List.unmodifiable(timeline),
      selectedTimeline: List.unmodifiable(timeline),
      isLoadingSources: false,
    );
  }

  Future<void> generateDiary() async {
    if (state.isLoading) return;

    state = state.copyWith(isLoading: true, clearError: true);

    try {
      // ユーザーが選んだ情報だけをAIに渡して、日記を書いてもらう
      final result = await _generateDiaryUseCase.execute(
        title: state.title,
        content: state.content,
        startDate: state.startDate,
        endDate: state.endDate,
        photos: state.selectedPhotos,
        timeline: state.selectedTimeline,
        posts: state.selectedPosts,
      );

      if (_isDisposed) return;

      state = state.copyWith(
        generatedDiary: result,
        isLoading: false,
      );
    } on AiUploadException catch (e, stackTrace) {
      debugPrint(e.toString());
      debugPrintStack(stackTrace: stackTrace);

      if (_isDisposed) return;

      state = state.copyWith(
        isLoading: false,
        errorMessage: "写真のアップロードに失敗しました",
      );
    } catch (e, stackTrace) {
      debugPrint(e.toString());
      debugPrintStack(stackTrace: stackTrace);

      if (_isDisposed) return;

      state = state.copyWith(
        isLoading: false,
        errorMessage: "生成に失敗しました",
      );
    }
  }
}
