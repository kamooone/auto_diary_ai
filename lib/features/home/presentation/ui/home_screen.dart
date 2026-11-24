import 'package:auto_diary_ai/common/extensions/build_context_ext.dart';
import 'package:auto_diary_ai/common/widgets/month_bar.dart';
import 'package:auto_diary_ai/features/home/presentation/ui/widgets/diary_timeline_view.dart';
import 'package:auto_diary_ai/features/home/presentation/ui/widgets/home_fab.dart';
import 'package:auto_diary_ai/features/home/presentation/ui/widgets/home_scaffold.dart';
import 'package:auto_diary_ai/features/home/presentation/ui/widgets/trail_illustration.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:auto_diary_ai/app/router/app_routes.dart';
import 'package:auto_diary_ai/features/home/presentation/providers/home_providers.dart';
import 'package:auto_diary_ai/features/location/application/providers/location_providers.dart';
import '../../../ads/application/ads_provider.dart';
import '../../../ads/presentation/banner_ad_view.dart';
import '../../../inquiry/application/providers/inquiry_providers.dart';
import '../../../memo/presentation/ui/memo_edit_dialog.dart';
import '../../../memo/presentation/ui/memo_list_view.dart';
import '../../../tutorial/application/tutorial_providers.dart';
import '../../../tutorial/domain/tutorial_step.dart';
import '../../../tutorial/presentation/tutorial_runner.dart';
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

  // チュートリアルで明るくする部品
  final _diaryTabKey = GlobalKey();
  final _memoTabKey = GlobalKey();
  final _createKey = GlobalKey();
  final _calendarKey = GlobalKey();
  final _mapKey = GlobalKey();
  final _menuKey = GlobalKey();

  // この画面のチュートリアルの印(見たかどうかを覚えるときの名前)
  static const _tutorialId = 'home';

  @override
  void initState() {
    super.initState();

    pageController = PageController();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // 初めて表示したときは、先にチュートリアルを出す(ダイアログは、そのあと)
      await _showTutorialOnce();
      await _promptRecordingWidget();
    });
  }

  // 紹介のあと、作成ボタン、下のタブ、画面の上の部品の順に、1つずつ説明する(初めて表示したときだけ)
  Future<void> _showTutorialOnce() async {
    final store = ref.read(tutorialSeenStoreProvider);
    if (await store.hasSeen(_tutorialId)) return;
    if (!mounted) return;

    await showTutorial(context, [
      // 最初に、どんなアプリかを説明する
      const TutorialStep.intro(
        title: "アプリをインストールしていただき、ありがとうございます",
        body:
            "このアプリでは、行動の記録や写真、メモなど、日記の材料を簡単に集められるので、手軽に日記を作成できます。\n\n"
            "これから機能を一つ一つ簡単に説明しますのでご覧ください。",
      ),
      TutorialStep(
        target: _createKey,
        title: "作成ボタン",
        body: "日記タブでは日記作成画面に、ひとことタブではひとこと作成画面に移ります。",
        bubbleAbove: true,
      ),
      TutorialStep(
        target: _diaryTabKey,
        title: "日記タブ",
        body: "作成した日記が、ここに表示されます。",
        bubbleAbove: true,
      ),
      TutorialStep(
        target: _memoTabKey,
        title: "ひとことタブ",
        body: "ふと思ったことなどを、気軽に残せます。日記を作成するときの材料にもなります。",
        bubbleAbove: true,
      ),
      TutorialStep(
        target: _calendarKey,
        title: "カレンダー",
        body: "作成した日記を、カレンダーで確認できます。",
        circle: true,
      ),
      TutorialStep(
        target: _mapKey,
        title: "行動履歴",
        body: "地図とタイムラインで、行動の記録を確認できます。",
        circle: true,
      ),
      TutorialStep(
        target: _menuKey,
        title: "メニュー",
        body: "設定やお問い合わせなどの画面に移ります。",
        circle: true,
      ),
    ]);

    await store.markSeen(_tutorialId);
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
        scrollable: true,
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

    ref.listen<String>(selectedMonthProvider, (prev, next) {
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
    });

    return HomeScaffold(
      title: context.l10n.appTitle,

      actions: [
        IconButton(
          key: _calendarKey,
          icon: const Icon(Icons.calendar_month_outlined),
          tooltip: "カレンダー",
          onPressed: () {
            context.push(AppRoutes.calendar);
          },
        ),
        IconButton(
          key: _mapKey,
          icon: const Icon(Icons.map_outlined),
          tooltip: "地図",
          onPressed: () async {
            // 地図を表示する直前に、広告を表示する
            await ref.read(adPolicyProvider).beforeMap();
            if (!context.mounted) return;

            context.push(AppRoutes.map);
          },
        ),
        IconButton(
          key: _menuKey,
          tooltip: "メニュー",
          // お問い合わせに、新しい返信があるときは、印を付ける
          icon: Badge(
            // 小さすぎて気づきにくいので、標準(6)の3倍にする
            smallSize: 18,
            isLabelVisible:
                ref.watch(hasUnreadReplyProvider).valueOrNull ?? false,
            child: const Icon(Icons.menu),
          ),
          onPressed: () async {
            await context.push(AppRoutes.settings);
            ref.invalidate(hasUnreadReplyProvider);
            // 設定で「使い方の説明をもう一度見る」を選んだときは、戻ってすぐに出す
            if (mounted) await _showTutorialOnce();
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

          // 下部：バナー広告(読み込めたときだけ、白い帯で出す)
          const BannerAdView(band: true),
        ],
      ),

      bottomNavigationBar: NavigationBar(
        selectedIndex: _tabIndex,
        onDestinationSelected: (index) => setState(() => _tabIndex = index),
        destinations: [
          NavigationDestination(
            key: _diaryTabKey,
            icon: Icon(Icons.menu_book_outlined),
            selectedIcon: Icon(Icons.menu_book),
            label: "日記",
          ),
          NavigationDestination(
            key: _memoTabKey,
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
            child: SingleChildScrollView(
              child: TrailIllustration(
                message: "まだ日記がありません\n右下のボタンから日記を作成できます",
              ),
            ),
          )
        else if (state.months.contains(selectedMonth))
          Column(
            children: [
              MonthBar(
                months: state.months,
                selectedMonth: selectedMonth,
                onChanged: viewModel.setMonth,
              ),
              Expanded(
                child: DiaryTimelineView(
                  months: state.months,
                  itemsPerMonth: state.filteredItemsPerMonth,
                  pageController: pageController,
                  onPageChanged: viewModel.onPageChanged,
                ),
              ),
            ],
          ),

        // 右下：日記作成(一覧の上に重ねる)
        Positioned(
          right: 16,
          bottom: 16,
          child: HomeFab(
            key: _createKey,
            heroTag: 'diary',
            tooltip: '日記作成',
            label: '日記を書く',
            onPressed: () {
              context.push(AppRoutes.diaryCreate);
            },
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
          bottom: 16,
          child: HomeFab(
            heroTag: 'memo',
            tooltip: 'ひとことメモを追加',
            label: 'ひとこと',
            onPressed: () => showMemoEditDialog(context),
          ),
        ),
      ],
    );
  }
}
