import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:auto_diary_ai/features/home/data/models/diary_item.dart';
import 'package:auto_diary_ai/features/home/presentation/providers/home_providers.dart';

class HomeViewModel extends Notifier<HomeState> {
  @override
  HomeState build() {
    _init();
    return state;
  }

  void _init() {
    final diaryItems = ref.read(diaryProvider);
    final months = diaryItems.map((e) => e.date.substring(0, 7)).toSet().toList()
      ..sort();

    final selectedMonth = ref.read(selectedMonthProvider);
    final initialPage = months.indexOf(selectedMonth);

    final filteredItemsPerMonth = {
      for (var month in months)
        month: diaryItems.where((item) => item.date.startsWith(month)).toList()
    };

    state = HomeState(
      pageController: PageController(initialPage: initialPage),
      months: months,
      selectedMonth: selectedMonth,
      filteredItemsPerMonth: filteredItemsPerMonth,
    );
  }

  void setMonth(String month) {
    final index = state.months.indexOf(month);
    state.pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
    ref.read(selectedMonthProvider.notifier).setMonth(month);
    state = state.copyWith(selectedMonth: month);
  }

  void onPageChanged(int index) {
    final month = state.months[index];
    ref.read(selectedMonthProvider.notifier).setMonth(month);
    state = state.copyWith(selectedMonth: month);
  }
}

class HomeState {
  final PageController pageController;
  final List<String> months;
  final String selectedMonth;
  final Map<String, List<DiaryItem>> filteredItemsPerMonth;

  const HomeState({
    required this.pageController,
    required this.months,
    required this.selectedMonth,
    required this.filteredItemsPerMonth,
  });

  factory HomeState.initial() => HomeState(
    pageController: PageController(),
    months: const [],
    selectedMonth: '',
    filteredItemsPerMonth: const {},
  );

  HomeState copyWith({
    PageController? pageController,
    List<String>? months,
    String? selectedMonth,
    Map<String, List<DiaryItem>>? filteredItemsPerMonth,
  }) {
    return HomeState(
      pageController: pageController ?? this.pageController,
      months: months ?? this.months,
      selectedMonth: selectedMonth ?? this.selectedMonth,
      filteredItemsPerMonth: filteredItemsPerMonth ?? this.filteredItemsPerMonth,
    );
  }
}

final homeViewModelProvider = NotifierProvider<HomeViewModel, HomeState>(HomeViewModel.new);
