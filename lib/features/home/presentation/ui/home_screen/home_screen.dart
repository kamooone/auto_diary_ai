import 'package:auto_diary_ai/common/extensions/build_context_ext.dart';
import 'package:auto_diary_ai/features/home/presentation/ui/home_screen/viewmodel/home_view_model.dart';
import 'package:auto_diary_ai/features/home/presentation/ui/home_screen/widgets/home_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:auto_diary_ai/app/router/app_routes.dart';
import 'package:auto_diary_ai/features/home/presentation/providers/home_providers.dart';
import 'widgets/diary_list_view.dart';
import 'widgets/month_dropdown.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  late final PageController pageController;

  @override
  void initState() {
    super.initState();

    pageController = PageController();
  }

  @override
  void dispose() {
    pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(homeViewModelProvider);
    final viewModel = ref.read(homeViewModelProvider.notifier);
    final selectedMonth = ref.watch(selectedMonthProvider);

    ref.listen<String>(
      selectedMonthProvider,
          (prev, next) {
        if (prev == next) return;

        final index = state.months.indexOf(next);

        if (index >= 0) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            pageController.animateToPage(
              index,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            );
          });
        }
      },
    );

    return HomeScaffold(
      title: context.l10n.appTitle,

      actions: [
        IconButton(
          icon: const Icon(Icons.settings),
          onPressed: () {},
        ),
      ],

      floatingActionButton: FloatingActionButton(
        tooltip: '日記を作成',
        onPressed: () {
          context.push(AppRoutes.diaryCreate);
        },
        child: const Icon(Icons.add),
      ),

      body: Column(
        children: [
          MonthDropdown(
            months: state.months,
            selectedMonth: selectedMonth,
            onChanged: (month) {
              viewModel.setMonth(month);
            },
          ),
          Expanded(
            child: DiaryListView(
              months: state.months,
              filteredItemsPerMonth: state.filteredItemsPerMonth,
              pageController: pageController,
              onPageChanged: viewModel.onPageChanged,
            ),
          ),
        ],
      ),
    );
  }
}