import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:auto_diary_ai/features/home/data/models/diary_item.dart';

final diaryProvider = Provider<List<DiaryItem>>((ref) => dummyDiaryItems);

// 月選択を管理するNotifier
class SelectedMonthNotifier extends Notifier<String> {
  @override
  String build() => '2025-11';

  void setMonth(String month) {
    state = month;
  }
}

// NotifierProvider
final selectedMonthProvider = NotifierProvider<SelectedMonthNotifier, String>(SelectedMonthNotifier.new);
