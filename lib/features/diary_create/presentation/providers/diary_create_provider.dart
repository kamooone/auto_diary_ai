import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../viewmodel/diary_create_view_model.dart';

final diaryCreateProvider =
NotifierProvider<DiaryCreateViewModel, DiaryCreateState>(
  DiaryCreateViewModel.new,
);