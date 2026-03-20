import 'package:auto_diary_ai/features/home/presentation/ui/home_screen/viewmodel/home_view_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:auto_diary_ai/l10n/app_localizations.dart';
import 'widgets/diary_list_view.dart';
import 'widgets/month_dropdown.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(homeViewModelProvider);
    final viewModel = ref.read(homeViewModelProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)?.appTitle ?? ''),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
         MonthDropdown(
           months: state.months,
           selectedMonth: state.selectedMonth,
           onChanged: viewModel.setMonth,
         ),

          Expanded(
            child: DiaryListView(
              months: state.months,
              filteredItemsPerMonth: state.filteredItemsPerMonth,
              pageController: state.pageController,
              onPageChanged: viewModel.onPageChanged,
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          context.push('/diary_create_screen');
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
