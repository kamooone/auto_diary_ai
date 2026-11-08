import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../viewmodel/diary_create_view_model.dart';

// 画面を開くたびに入力内容を初期化するため、画面を閉じたら破棄する
final diaryCreateProvider =
NotifierProvider.autoDispose<DiaryCreateViewModel, DiaryCreateState>(
  DiaryCreateViewModel.new,
);
