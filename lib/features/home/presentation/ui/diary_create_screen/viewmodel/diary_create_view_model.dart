import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import 'package:photo_manager/photo_manager.dart';

/// Riverpod
final diaryCreateProvider = NotifierProvider<DiaryCreateViewModel, DiaryCreateState>(
  DiaryCreateViewModel.new,
);

class DiaryCreateState {
  final String inputText;
  final String generatedDiary;
  final bool isLoading;
  final DateTime selectedDate;

  DiaryCreateState({
    this.inputText = '',
    this.generatedDiary = '',
    this.isLoading = false,
    required this.selectedDate,
  });

  // copyWith を使えば、変更したいところだけを書けば済む
  DiaryCreateState copyWith({
    String? inputText,
    String? generatedDiary,
    bool? isLoading,
    DateTime? selectedDate,
  }) {
    return DiaryCreateState(
      inputText: inputText ?? this.inputText,
      generatedDiary: generatedDiary ?? this.generatedDiary,
      isLoading: isLoading ?? this.isLoading,
      selectedDate: selectedDate ?? this.selectedDate,
    );
  }
}

class DiaryCreateViewModel extends Notifier<DiaryCreateState> {

  String? _sharedPost;

  @override
  DiaryCreateState build() {
    // build メソッド内で初期値を設定する
    final now = DateTime.now();
    return DiaryCreateState(
      selectedDate: DateTime(now.year, now.month, now.day),
    );
  }

  // TODO: 日記作成画面に日付選択セレクトボックスを追加する
  void setSelectedDate(DateTime date) {
    state = state.copyWith(selectedDate: date);
  }

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
    await Future.delayed(const Duration(seconds: 2)); // TODO: 仮で2秒停止しているだけ
    final generated = "AIが作った日記: ${state.inputText}";

    state = state.copyWith(generatedDiary: generated, isLoading: false);
  }

  Future<void> pickPhoto() async {
    // 1. 権限リクエスト
    final permission = await PhotoManager.requestPermissionExtend(
      requestOption: const PermissionRequestOption(
        androidPermission: AndroidPermission(
          type: RequestType.image,
          mediaLocation: false,
        ),
      ),
    );

    if (!permission.hasAccess) {
      debugPrint('写真権限なし');
      return;
    }

    state = state.copyWith(isLoading: true);

    // 2. フィルタ設定（新しい順）
    final filter = FilterOptionGroup(
      orders: [
        const OrderOption(
          type: OrderOptionType.createDate,
          asc: false, // 降順（新しい順）
        ),
      ],
    );

    // 3. 全アルバム取得
    final albums = await PhotoManager.getAssetPathList(
      type: RequestType.image,
      onlyAll: true,
      filterOption: filter,
    );

    if (albums.isEmpty) {
      debugPrint('アルバムなし');
      state = state.copyWith(isLoading: false);
      return;
    }

    /// albums.firstで全ての写真を取得出来ているはずだが、万が一この通りじゃない端末があった場合は対応する
    final album = albums.first;

    final targetDate = state.selectedDate;
    final startOfDay = DateTime(targetDate.year, targetDate.month, targetDate.day);
    final endOfDay = startOfDay.add(const Duration(days: 1)); // 範囲判定をより正確にするため

    final List<AssetEntity> todayPhotos = [];
    int page = 0;
    const int pageSize = 50; // 1ページ50件ずつ取得

    // ページネーションループ
    while (true) {
      final photos = await album.getAssetListPaged(
        page: page,
        size: pageSize,
      );

      if (photos.isEmpty) break;

      // このページ内で今日の日付のものを判定
      bool foundOldPhoto = false;
      for (final photo in photos) {
        // ★ 判定ロジックも、startOfDay から endOfDay の範囲に変えておくと完璧
        if (photo.createDateTime.isAfter(startOfDay) && photo.createDateTime.isBefore(endOfDay)) {
          todayPhotos.add(photo);
        } else if (photo.createDateTime.isBefore(startOfDay)) {
          foundOldPhoto = true;
          break;
        }
      }

      if (foundOldPhoto) break;
      page++;
    }

    debugPrint('今日の写真数: ${todayPhotos.length}');

    for (final photo in todayPhotos) {
      debugPrint('写真: ${photo.title} 撮影日時: ${photo.createDateTime}');
    }

    state = state.copyWith(isLoading: false);
  }
}
