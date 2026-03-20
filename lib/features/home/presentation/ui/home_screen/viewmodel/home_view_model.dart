import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:auto_diary_ai/features/home/data/models/diary_item.dart';
import 'package:auto_diary_ai/features/home/presentation/providers/home_providers.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
part 'home_view_model.freezed.dart';

class HomeViewModel extends Notifier<HomeState> {
  @override
  HomeState build() {
    final diaryItems = ref.watch(diaryProvider);
    final selectedMonth = ref.watch(selectedMonthProvider);

    final months = diaryItems
        .map((e) => e.date.substring(0, 7))
        .toSet()
        .toList()
      ..sort();

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
        month: diaryItems
            .where((item) => item.date.startsWith(month))
            .toList()
    };

    return HomeState(
      months: months,
      filteredItemsPerMonth: filteredItemsPerMonth,
    );
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
abstract class HomeState with _$HomeState {
  const factory HomeState({
    required List<String> months,
    required Map<String, List<DiaryItem>> filteredItemsPerMonth,
  }) = _HomeState;
}

final homeViewModelProvider = NotifierProvider<HomeViewModel, HomeState>(HomeViewModel.new);
