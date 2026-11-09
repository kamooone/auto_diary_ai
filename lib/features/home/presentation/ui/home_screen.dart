import 'package:auto_diary_ai/common/extensions/build_context_ext.dart';
import 'package:auto_diary_ai/features/home/presentation/ui/widgets/diary_list_view.dart';
import 'package:auto_diary_ai/features/home/presentation/ui/widgets/home_scaffold.dart';
import 'package:auto_diary_ai/features/home/presentation/ui/widgets/year_month_dropdown.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:auto_diary_ai/app/router/app_routes.dart';
import 'package:auto_diary_ai/core/app_info/app_version_provider.dart';
import 'package:auto_diary_ai/features/home/presentation/providers/home_providers.dart';
import 'package:auto_diary_ai/features/location/application/providers/location_providers.dart';
import '../../../ads/application/ads_provider.dart';
import '../../../ads/presentation/banner_ad_view.dart';
import '../../../memo/presentation/ui/memo_edit_dialog.dart';
import '../../../memo/presentation/ui/memo_list_view.dart';
import '../viewmodel/home_view_model.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  late final PageController pageController;

  // 0: 日記、1: ひとことメモ
  var _tabIndex = 0;

  @override
  void initState() {
    super.initState();

    pageController = PageController();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _promptRecordingWidget();
    });
  }

  // 行動履歴のオン・オフを切り替えるボタンを、ホーム画面に置くかどうかを尋ねる(初回のみ)
  Future<void> _promptRecordingWidget() async {
    final dataSource = ref.read(recordingStateDataSourceProvider);

    if (!await dataSource.isWidgetPinSupported()) return;
    if (await dataSource.isWidgetPinned()) return;
    if (!await dataSource.consumeWidgetPrompt()) return;

    if (!mounted) return;

    final shouldAdd = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("ホーム画面にボタンを表示しますか？"),
        content: const Text(
          "行動履歴のオン・オフを切り替えるボタンを、ホーム画面に表示できます。\n"
          "表示すると、オン・オフの切り替えがすぐにできます。\n\n"
          "あとから設定画面でも表示できます。",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text("表示しない"),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text("表示する"),
          ),
        ],
      ),
    );

    if (shouldAdd == true) {
      await dataSource.requestPinWidget();
    }
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
          icon: const Icon(Icons.calendar_month),
          tooltip: "カレンダー",
          onPressed: () {
            context.push(AppRoutes.calendar);
          },
        ),
        IconButton(
          icon: const Icon(Icons.map),
          tooltip: "地図",
          onPressed: () async {
            // 地図を表示する直前に、広告を表示する
            await ref.read(adPolicyProvider).beforeMap();
            if (!context.mounted) return;

            context.push(AppRoutes.map);
          },
        ),
        IconButton(
          icon: const Icon(Icons.settings),
          onPressed: () {
            context.push(AppRoutes.settings);
          },
        ),
      ],

      body: Column(
        children: [
          // タブの中身。下の作成ボタンとバナー広告には被らない
          // (タブを切り替えても、日記の月の選択やスクロールの位置を保つため、両方を持ち続ける)
          Expanded(
            child: IndexedStack(
              index: _tabIndex,
              children: [
                _diaryTab(state, viewModel, selectedMonth),
                const _MemoTab(),
              ],
            ),
          ),

          // 下部：バナー広告、バージョンの表示
          // (バナー広告を読み込めていない間は、広告の分の空きを作らない)
          const SizedBox(height: 4),
          const BannerAdView(),
          const SizedBox(height: 4),

          // どの版のアプリが入っているかを確認するための表示
          Text(
            "バージョン ${ref.watch(appVersionProvider).valueOrNull ?? ""}",
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: Colors.grey),
          ),
          const SizedBox(height: 8),
        ],
      ),

      bottomNavigationBar: NavigationBar(
        selectedIndex: _tabIndex,
        onDestinationSelected: (index) => setState(() => _tabIndex = index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.menu_book_outlined),
            selectedIcon: Icon(Icons.menu_book),
            label: "日記",
          ),
          NavigationDestination(
            icon: Icon(Icons.edit_note_outlined),
            selectedIcon: Icon(Icons.edit_note),
            label: "ひとこと",
          ),
        ],
      ),
    );
  }

  // 「日記」タブ: 日記の一覧と、日記を作るボタン
  Widget _diaryTab(
    HomeUiModel state,
    HomeViewModel viewModel,
    String selectedMonth,
  ) {
    return Stack(
      children: [
        // 月の切り替えは、選択中の月が一覧に反映されてから表示する
        if (state.months.isEmpty)
          const Center(
            child: Text("まだ日記がありません\n右下のボタンから日記を作成できます"),
          )
        else if (state.months.contains(selectedMonth))
          Column(
            children: [
              YearMonthDropdown(
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

        // 右下：日記作成(一覧の上に重ねる)
        Positioned(
          right: 16,
          bottom: 8,
          child: FloatingActionButton(
            heroTag: 'diary',
            tooltip: '日記作成',
            onPressed: () {
              context.push(AppRoutes.diaryCreate);
            },
            child: const Icon(Icons.add),
          ),
        ),
      ],
    );
  }
}

/// 「ひとこと」タブ: ひとことメモの一覧と、メモを追加するボタン
class _MemoTab extends StatelessWidget {
  const _MemoTab();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const MemoListView(),

        // 右下：メモの追加(一覧の上に重ねる)
        Positioned(
          right: 16,
          bottom: 8,
          child: FloatingActionButton(
            heroTag: 'memo',
            tooltip: 'ひとことメモを追加',
            onPressed: () => showMemoEditDialog(context),
            child: const Icon(Icons.add),
          ),
        ),
      ],
    );
  }
}
