import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/router/app_routes.dart';
import '../../../../core/app_info/install_date_provider.dart';
import '../../../ads/application/ads_provider.dart';
import '../../../plan/application/providers/plan_provider.dart';
import '../viewmodel/diary_create_view_model.dart';
import '../../../plan/domain/entities/plan_availability.dart';
import '../../../plan/presentation/widgets/usage_limit_guidance.dart';
import '../../../plan/presentation/widgets/usage_meter.dart';
import '../../../location/domain/entities/timeline_item.dart';
import '../../../share/domain/entities/shared_post.dart';
import '../../application/providers/diary_usecase_providers.dart';
import '../providers/diary_create_provider.dart';
import 'diary_result_screen.dart';
import 'post_select_page.dart';
import 'timeline_select_page.dart';
import 'widgets/diary_period_text.dart';
import 'widgets/photo_selection_card.dart';

/// AIに日記を書いてもらうための情報を選択する画面
class DiaryAiScreen extends ConsumerStatefulWidget {
  const DiaryAiScreen({super.key});

  @override
  ConsumerState<DiaryAiScreen> createState() => _DiaryAiScreenState();
}

class _DiaryAiScreenState extends ConsumerState<DiaryAiScreen> {
  // この画面を開き直したときに、入力済みの内容を表示する
  late final _noteController = TextEditingController(
    text: ref.read(diaryCreateProvider).aiNote,
  );

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();

    // この画面を開いたときに、選んだ日のXの投稿と行動履歴を読み込む
    Future.microtask(() {
      ref.read(diaryCreateProvider.notifier).loadSources();

      // 今月の使用量を取得する
      ref.read(usageProvider.notifier).refresh();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(diaryCreateProvider);
    final viewModel = ref.read(diaryCreateProvider.notifier);
    final plan = ref.watch(diaryPlanProvider);
    final usage = ref.watch(usageProvider);
    final isExceeded = usage?.isExceeded ?? false;

    return Scaffold(
      appBar: AppBar(title: const Text("AIに書いてもらう")),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 何月何日の日記を書くか(プランに関わらず1日だけ)
          Card(
            child: ListTile(
              leading: const Icon(Icons.calendar_today),
              title: const Text("日記の日付"),
              subtitle: Text(
                DiaryPeriodText.format(state.startDate, state.startDate),
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _selectDiaryDate(context, state),
            ),
          ),

          // 有料プランだけ、AIに渡す情報の期間を選べる
          // (無料プランは、日記の日付と同じ日の情報だけを渡せる)
          if (plan.allowsMultipleDays) ...[
            const SizedBox(height: 4),
            Card(
              child: ListTile(
                leading: const Icon(Icons.date_range),
                title: const Text("AIに渡す情報の期間"),
                subtitle: Text(
                  DiaryPeriodText.format(state.aiStartDate, state.aiEndDate),
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _selectPeriod(context, state),
              ),
            ),
          ],
          const SizedBox(height: 4),
          Text(
            plan.allowsMultipleDays
                ? "写真・Xの投稿・行動履歴は、選んだ期間のものから選べます"
                : "写真・Xの投稿・行動履歴は、日記の日付のものから選べます",
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 12),

          // 今月の使用量。上限に達している場合は、使えるようになる時期を伝える
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  UsageMeter(usage: usage),
                  if (isExceeded) ...[
                    const SizedBox(height: 8),
                    if (paidPlanEnabled)
                      Text(
                        plan.type.isPaid
                            ? "今月の使用量の上限に達しました。次のリセットまでAIは使えません。"
                            : "今月の使用量の上限に達しました。有料プランにすると、"
                                  "さらに多く使えます。",
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      )
                    else
                      const UsageLimitGuidance(),
                    if (paidPlanEnabled && !plan.type.isPaid)
                      TextButton(
                        onPressed: () => context.push(AppRoutes.plan),
                        child: const Text("プランを見る"),
                      ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // AIには、日記の日付に撮影した写真だけを渡せる
          PhotoSelectionCard(
            photos: state.aiPhotos,
            maxPhotos: plan.maxPhotos,
            from: state.aiStartDate,
            // 対象期間の最終日の終わりまで
            to: DateTime(
              state.aiEndDate.year,
              state.aiEndDate.month,
              state.aiEndDate.day + 1,
            ),
            onChanged: viewModel.setAiPhotos,
          ),
          const SizedBox(height: 4),

          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.share),
                  title: const Text("Xの投稿"),
                  subtitle: Text(
                    _selectionText(
                      isLoading: state.isLoadingSources,
                      total: state.posts.length,
                      selected: state.selectedPosts.length,
                      emptyText: "この日の投稿はありません",
                    ),
                  ),
                  trailing: _trailing(state.isLoadingSources),
                  enabled: state.posts.isNotEmpty,
                  onTap: () async {
                    final posts = await Navigator.of(context)
                        .push<List<SharedPost>>(
                          MaterialPageRoute(
                            fullscreenDialog: true,
                            builder: (context) => PostSelectPage(
                              posts: state.posts,
                              initialSelection: state.selectedPosts,
                            ),
                          ),
                        );

                    if (posts != null) {
                      viewModel.setSelectedPosts(posts);
                    }
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.timeline),
                  title: const Text("行動履歴"),
                  subtitle: Text(
                    _selectionText(
                      isLoading: state.isLoadingSources,
                      total: state.timeline.length,
                      selected: state.selectedTimeline.length,
                      emptyText: "この日の行動履歴はありません",
                    ),
                  ),
                  trailing: _trailing(state.isLoadingSources),
                  enabled: state.timeline.isNotEmpty,
                  onTap: () async {
                    final items = await Navigator.of(context)
                        .push<List<TimelineItem>>(
                          MaterialPageRoute(
                            fullscreenDialog: true,
                            builder: (context) => TimelineSelectPage(
                              items: state.timeline,
                              initialSelection: state.selectedTimeline,
                            ),
                          ),
                        );

                    if (items != null) {
                      viewModel.setSelectedTimeline(items);
                    }
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // ---------- AIに追加で伝えたいこと
          TextField(
            controller: _noteController,
            decoration: const InputDecoration(
              labelText: "AIに追加で伝えたいこと",
              hintText: "例: 友人の誕生日だった。楽しかった気持ちを中心に書いてほしい",
              border: OutlineInputBorder(),
              alignLabelWithHint: true,
            ),
            keyboardType: TextInputType.multiline,
            minLines: 3,
            maxLines: 8,
            onChanged: viewModel.setAiNote,
          ),
          const SizedBox(height: 16),

          // ---------- 生成
          ElevatedButton.icon(
            // 読み込みが終わるまでは、選択内容が確定しないため押せないようにする
            // 今月の使用量の上限に達している場合も、押せない
            onPressed: state.isLoadingSources || isExceeded
                ? null
                : () => _generate(context),
            icon: const Icon(Icons.auto_awesome),
            label: const Text("AIに日記を書いてもらう"),
          ),
        ],
      ),
    );
  }

  // リワード広告を見たあとに、AIに日記を書いてもらう
  Future<void> _generate(BuildContext context) async {
    // 広告を見る必要があることを伝えて、許可をもらう
    final agreed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("広告を見ますか？"),
        content: const Text("AIに日記を書いてもらうには、広告(動画)を最後まで見る必要があります。"),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text("やめる"),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text("広告を見る"),
          ),
        ],
      ),
    );

    if (agreed != true || !context.mounted) return;

    final allowed = await ref.read(adPolicyProvider).beforeGenerate();

    if (!allowed) {
      if (!context.mounted) return;

      // 広告を最後まで見ないと、日記を書いてもらえない
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("広告を最後まで見ると、AIに日記を書いてもらえます")),
      );
      return;
    }

    if (!context.mounted) return;

    ref.read(diaryCreateProvider.notifier).generateDiary();

    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => const DiaryResultScreen()));
  }

  // アプリを使い始めた日から今日までが、選べる範囲
  ({DateTime first, DateTime last}) _selectableDates() {
    final now = DateTime.now();
    final installDate = ref.read(installDateProvider);

    return (
      first: DateTime(installDate.year, installDate.month, installDate.day),
      last: DateTime(now.year, now.month, now.day),
    );
  }

  Future<void> _selectDiaryDate(
    BuildContext context,
    DiaryCreateState state,
  ) async {
    final dates = _selectableDates();

    final selected = await showDatePicker(
      context: context,
      initialDate: state.startDate,
      firstDate: dates.first,
      lastDate: dates.last,
    );

    if (selected != null) {
      final viewModel = ref.read(diaryCreateProvider.notifier);
      viewModel.setDate(selected);

      // 日付が変わると、AIに渡せる情報も変わるため、読み込み直す
      await viewModel.loadSources();
    }
  }

  // 有料プランだけ
  Future<void> _selectPeriod(
    BuildContext context,
    DiaryCreateState state,
  ) async {
    final dates = _selectableDates();

    final range = await showDateRangePicker(
      context: context,
      initialDateRange: DateTimeRange(
        start: state.aiStartDate,
        end: state.aiEndDate,
      ),
      firstDate: dates.first,
      lastDate: dates.last,
      helpText: "AIに渡す情報の期間",
    );

    if (range != null) {
      final viewModel = ref.read(diaryCreateProvider.notifier);
      viewModel.setAiDateRange(range.start, range.end);

      // 期間が変わると、AIに渡せる情報も変わるため、読み込み直す
      await viewModel.loadSources();
    }
  }

  // 読み込みが終わるまではインジケータを表示する
  Widget _trailing(bool isLoading) {
    if (!isLoading) return const Icon(Icons.chevron_right);

    return const SizedBox(
      width: 16,
      height: 16,
      child: CircularProgressIndicator(strokeWidth: 2),
    );
  }

  String _selectionText({
    required bool isLoading,
    required int total,
    required int selected,
    required String emptyText,
  }) {
    if (isLoading) return "読み込み中…";
    if (total == 0) return emptyText;
    return "$total件中$selected件を選択中";
  }
}
