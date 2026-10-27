import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import '../../../../core/logging/app_log.dart';
import '../../../ai/domain/exceptions/ai_exception.dart';
import '../../../diary/application/providers/diary_providers.dart';
import '../../../diary/domain/entities/diary.dart';
import '../../../location/application/providers/location_providers.dart';
import '../../../plan/application/providers/plan_provider.dart';
import '../../../plan/domain/exceptions/usage_limit_exception.dart';
import '../../../location/domain/entities/timeline_item.dart';
import '../../../share/application/providers/share_providers.dart';
import '../../../share/domain/entities/shared_post.dart';
import '../../application/providers/diary_usecase_providers.dart';
import '../../domain/entities/photo.dart';

class DiaryCreateState {
  /// 自分で書く日記のタイトルと本文
  final String title;
  final String content;

  /// AIに書いてもらうときに、追加で伝えたい内容
  final String aiNote;

  /// AIが書いた日記のタイトルと本文
  final String generatedTitle;
  final String generatedDiary;

  final String? errorMessage;
  final bool isLoading;

  /// 自分で書く日記の日付(startDateとendDateは同じ日)
  final DateTime startDate;
  final DateTime endDate;

  /// AIに渡す情報(写真・Xの投稿・行動履歴)の期間
  /// 無料プランは日記の日付と同じ1日分。有料プランは、選んだ期間
  final DateTime aiStartDate;
  final DateTime aiEndDate;

  /// 自分で書く日記に添える写真(撮影日の制限なし)
  final List<Photo> selectedPhotos;

  /// AIに渡す写真(日記の日付に撮影したもの)
  final List<Photo> aiPhotos;

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
    this.aiNote = '',
    this.generatedTitle = '',
    this.generatedDiary = '',
    this.errorMessage,
    this.isLoading = false,
    required this.startDate,
    required this.endDate,
    required this.aiStartDate,
    required this.aiEndDate,
    this.selectedPhotos = const [],
    this.aiPhotos = const [],
    this.posts = const [],
    this.selectedPosts = const [],
    this.timeline = const [],
    this.selectedTimeline = const [],
    this.isLoadingSources = false,
  });

  DiaryCreateState copyWith({
    String? title,
    String? content,
    String? aiNote,
    String? generatedTitle,
    String? generatedDiary,
    String? errorMessage,
    bool clearError = false,
    bool? isLoading,
    DateTime? startDate,
    DateTime? endDate,
    DateTime? aiStartDate,
    DateTime? aiEndDate,
    List<Photo>? selectedPhotos,
    List<Photo>? aiPhotos,
    List<SharedPost>? posts,
    List<SharedPost>? selectedPosts,
    List<TimelineItem>? timeline,
    List<TimelineItem>? selectedTimeline,
    bool? isLoadingSources,
  }) {
    return DiaryCreateState(
      title: title ?? this.title,
      content: content ?? this.content,
      aiNote: aiNote ?? this.aiNote,
      generatedTitle: generatedTitle ?? this.generatedTitle,
      generatedDiary: generatedDiary ?? this.generatedDiary,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      isLoading: isLoading ?? this.isLoading,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      aiStartDate: aiStartDate ?? this.aiStartDate,
      aiEndDate: aiEndDate ?? this.aiEndDate,
      selectedPhotos: selectedPhotos ?? this.selectedPhotos,
      aiPhotos: aiPhotos ?? this.aiPhotos,
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

    // 初期表示は今日の日記
    return DiaryCreateState(
      startDate: today,
      endDate: today,
      aiStartDate: today,
      aiEndDate: today,
    );
  }

  // Xの投稿と行動履歴を読み込み済みの対象期間
  DateTime? _loadedStart;
  DateTime? _loadedEnd;

  /// 日記の日付を変更する
  /// AIに渡す情報の期間も、その日の1日分に戻す(有料プランは、期間を選び直せる)
  /// 対象日が変わるとAIに渡せる情報も変わるため、AI用の選択内容は空に戻す
  /// (自分で書く日記に添える写真は、日付に関係ないためそのまま残す)
  void setDate(DateTime date) {
    final day = DateTime(date.year, date.month, date.day);

    state = state.copyWith(
      startDate: day,
      endDate: day,
      aiStartDate: day,
      aiEndDate: day,
      aiPhotos: const [],
      posts: const [],
      selectedPosts: const [],
      timeline: const [],
      selectedTimeline: const [],
    );

    _loadedStart = null;
    _loadedEnd = null;
  }

  /// AIに渡す情報の期間を変更する(有料プランのみ)
  /// 無料プランでは、日記の日付と同じ1日分のまま変わらない
  /// 期間が変わるとAIに渡せる情報も変わるため、AI用の選択内容は空に戻す
  void setAiDateRange(DateTime start, DateTime end) {
    // 無料プランでは、日記の日付の1日分だけ
    if (!ref.read(diaryPlanProvider).allowsMultipleDays) return;

    final first = DateTime(start.year, start.month, start.day);
    var last = DateTime(end.year, end.month, end.day);

    if (last.isBefore(first)) last = first;

    state = state.copyWith(
      aiStartDate: first,
      aiEndDate: last,
      aiPhotos: const [],
      posts: const [],
      selectedPosts: const [],
      timeline: const [],
      selectedTimeline: const [],
    );

    _loadedStart = null;
    _loadedEnd = null;
  }

  void setInputTitle(String text) {
    state = state.copyWith(title: text);
  }

  void setMainContent(String text) {
    state = state.copyWith(content: text);
  }

  void setAiNote(String text) {
    state = state.copyWith(aiNote: text);
  }

  // 自分で書く日記に添える写真をセット
  void setSelectedPhotos(List<Photo> photos) {
    state = state.copyWith(selectedPhotos: List.unmodifiable(photos));
  }

  // AIに渡す写真をセット
  void setAiPhotos(List<Photo> photos) {
    state = state.copyWith(aiPhotos: List.unmodifiable(photos));
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
  ///
  /// AIに書いてもらう画面を開いたときに呼ぶ。同じ期間をすでに読み込んでいる場合は、
  /// ユーザーの選択を保つため読み込み直さない
  Future<void> loadSources() async {
    final start = state.aiStartDate;
    final end = state.aiEndDate;

    if (state.isLoadingSources) return;
    if (_loadedStart == start && _loadedEnd == end) return;

    state = state.copyWith(isLoadingSources: true);

    final posts = <SharedPost>[];
    final timeline = <TimelineItem>[];

    try {
      final getSharedPosts = ref.read(getSharedPostsUseCaseProvider);
      final getTimeline = ref.read(getTimelineByDateUseCaseProvider);

      for (var day = start;
          !day.isAfter(end);
          day = DateTime(day.year, day.month, day.day + 1)) {
        posts.addAll(await getSharedPosts.execute(day));
        // 記録をオフにしていた時間帯は、AIに渡す情報ではないため選択肢に出さない
        timeline.addAll(
          (await getTimeline.execute(day)).where((e) => e is! RecordingOff),
        );
      }

      posts.sort((a, b) => a.receivedAt.compareTo(b.receivedAt));
    } catch (e, stackTrace) {
      debugPrint(e.toString());
      debugPrintStack(stackTrace: stackTrace);
    }

    if (_isDisposed) return;

    // 読み込み中に対象日が変更された場合は反映せず、新しい対象日で読み込み直す
    if (state.aiStartDate != start || state.aiEndDate != end) {
      state = state.copyWith(isLoadingSources: false);
      return loadSources();
    }

    _loadedStart = start;
    _loadedEnd = end;

    state = state.copyWith(
      posts: List.unmodifiable(posts),
      selectedPosts: List.unmodifiable(posts),
      timeline: List.unmodifiable(timeline),
      selectedTimeline: List.unmodifiable(timeline),
      isLoadingSources: false,
    );
  }

  /// 自分で書いた内容を、そのまま日記として保存する
  /// 保存できた場合はtrueを返す
  Future<bool> saveManualDiary() {
    return _saveDiary(
      title: state.title,
      content: state.content,
      photos: state.selectedPhotos,
      date: state.startDate,
      isAiGenerated: false,
    );
  }

  /// AIが書いた日記を保存する(確認画面でユーザーが修正した内容を受け取る)
  /// 保存できた場合はtrueを返す
  Future<bool> saveGeneratedDiary({
    required String title,
    required String content,
  }) {
    return _saveDiary(
      title: title,
      content: content,
      photos: state.aiPhotos,
      date: state.startDate,
      isAiGenerated: true,
    );
  }

  Future<bool> _saveDiary({
    required String title,
    required String content,
    required List<Photo> photos,
    required DateTime date,
    required bool isAiGenerated,
  }) async {
    try {
      await ref.read(saveDiaryUseCaseProvider).execute(
        Diary(
          date: date,
          title: title.trim(),
          content: content.trim(),
          isAiGenerated: isAiGenerated,
          photoIds: [for (final photo in photos) photo.id],
          createdAt: DateTime.now(),
        ),
      );
      return true;
    } catch (e, stackTrace) {
      debugPrint(e.toString());
      debugPrintStack(stackTrace: stackTrace);
      return false;
    }
  }

  Future<void> generateDiary() async {
    if (state.isLoading) return;

    state = state.copyWith(isLoading: true, clearError: true);

    try {
      // ユーザーが選んだ情報だけをAIに渡して、日記を書いてもらう
      final result = await _generateDiaryUseCase.execute(
        plan: ref.read(planTypeProvider),
        note: state.aiNote,
        diaryDate: state.startDate,
        startDate: state.aiStartDate,
        endDate: state.aiEndDate,
        photos: state.aiPhotos,
        timeline: state.selectedTimeline,
        posts: state.selectedPosts,
      );

      // 今月の使用量を、画面に反映する
      final usage = result.usage;
      if (usage != null) ref.read(usageProvider.notifier).update(usage);

      if (_isDisposed) return;

      state = state.copyWith(
        generatedTitle: result.title,
        generatedDiary: result.content,
        isLoading: false,
      );
    } on UsageLimitExceededException catch (e) {
      // 上限に達した場合は、使えるようになる時期を画面に示す
      final usage = e.usage;
      if (usage != null) ref.read(usageProvider.notifier).update(usage);

      if (_isDisposed) return;

      state = state.copyWith(
        isLoading: false,
        errorMessage: "今月のAIの使用量の上限に達しました",
      );
    } on AiUploadException catch (e, stackTrace) {
      AppLog.add('日記', '写真のアップロードに失敗: $e');
      debugPrint(e.toString());
      debugPrintStack(stackTrace: stackTrace);

      if (_isDisposed) return;

      state = state.copyWith(
        isLoading: false,
        errorMessage: "写真のアップロードに失敗しました",
      );
    } catch (e, stackTrace) {
      AppLog.add('日記', '生成に失敗: $e');
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
