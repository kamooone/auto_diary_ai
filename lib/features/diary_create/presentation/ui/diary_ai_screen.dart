import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/router/app_routes.dart';
import '../../../plan/application/providers/plan_provider.dart';
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
          Text(
            "${DiaryPeriodText.format(state.startDate, state.endDate)}の日記",
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 4),
          Text(
            "AIに渡す情報を選んでください",
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
                    Text(
                      plan.type.isPaid
                          ? "今月の使用量の上限に達しました。次のリセットまでAIは使えません。"
                          : "今月の使用量の上限に達しました。有料プランにすると、"
                              "さらに多く使えます。",
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                    if (!plan.type.isPaid)
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
            from: state.startDate,
            // 対象期間の最終日の終わりまで
            to: DateTime(
              state.endDate.year,
              state.endDate.month,
              state.endDate.day + 1,
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
                    final posts =
                        await Navigator.of(context).push<List<SharedPost>>(
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
                    final items =
                        await Navigator.of(context).push<List<TimelineItem>>(
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
                : () {
                    viewModel.generateDiary();

                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const DiaryResultScreen(),
                      ),
                    );
                  },
            icon: const Icon(Icons.auto_awesome),
            label: const Text("AIに日記を書いてもらう"),
          ),
        ],
      ),
    );
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
