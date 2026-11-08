import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:auto_diary_ai/features/diary/application/providers/diary_providers.dart';
import 'package:auto_diary_ai/features/diary/domain/entities/diary.dart';
import 'package:auto_diary_ai/features/home/presentation/providers/home_providers.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
part 'home_view_model.freezed.dart';

class HomeViewModel extends Notifier<HomeUiModel> {
  @override
  HomeUiModel build() {
    // 保存されている日記(新しい日付順)
    final diaries = ref.watch(diariesProvider).valueOrNull ?? const <Diary>[];
    final selectedMonth = ref.watch(selectedMonthProvider);

    final months = diaries
        .map((e) => _monthKey(e.date))
        .toSet()
        .toList()
      // 新しい月を先頭にする
      ..sort((a, b) => b.compareTo(a));

    // 選択中の月に日記がない場合は、最新の月を表示する
    final safeSelectedMonth =
    months.contains(selectedMonth)
        ? selectedMonth
        : (months.isNotEmpty ? months.first : '');

    if (safeSelectedMonth != selectedMonth) {
      Future.microtask(() {
        ref.read(selectedMonthProvider.notifier)
            .setMonth(safeSelectedMonth);
      });
    }

    final filteredItemsPerMonth = {
      for (var month in months)
        month: diaries
            .where((diary) => _monthKey(diary.date) == month)
            .toList()
    };

    return HomeUiModel(
      months: months,
      filteredItemsPerMonth: filteredItemsPerMonth,
    );
  }

  // 「2026-10」の形式
  String _monthKey(DateTime date) {
    return "${date.year}-${date.month.toString().padLeft(2, '0')}";
  }

  void setMonth(String month) {
    ref.read(selectedMonthProvider.notifier).setMonth(month);
  }

  void onPageChanged(int index) {
    if (index < 0 || index >= state.months.length) return;

    final month = state.months[index];
    ref.read(selectedMonthProvider.notifier).setMonth(month);
  }
}

@freezed
abstract class HomeUiModel with _$HomeUiModel {
  const factory HomeUiModel({
    required List<String> months,
    required Map<String, List<Diary>> filteredItemsPerMonth,
  }) = _HomeUiModel;
}

final homeViewModelProvider = NotifierProvider<HomeViewModel, HomeUiModel>(HomeViewModel.new);
