import 'package:auto_diary_ai/home/presentation/ui/widgets/diary_list_view.dart';
import 'package:auto_diary_ai/home/presentation/ui/widgets/home_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../viewmodels/home_view_model.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(homeViewModelProvider);
    final viewModel = ref.read(homeViewModelProvider.notifier);

    return Scaffold(
      appBar: HomeAppBar(
        months: state.months,
        selectedMonth: state.selectedMonth,
        onMonthChanged: viewModel.setMonth,
      ),
      body: DiaryListView(
        months: state.months,
        filteredItemsPerMonth: state.filteredItemsPerMonth,
        pageController: state.pageController,
        onPageChanged: viewModel.onPageChanged,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: 日記作成画面に遷移
        },
        child: const Icon(Icons.add_a_photo),
      ),
    );
  }
}
