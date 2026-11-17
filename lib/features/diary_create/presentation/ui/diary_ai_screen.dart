import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show ScrollCacheExtent;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../ads/presentation/banner_ad_view.dart';
import '../../../../core/app_info/install_date_provider.dart';
import '../../../ai/application/providers/ai_model_provider.dart';
import '../../../ai/presentation/widgets/ai_select_card.dart';
import '../../../../common/constants/app_colors.dart';
import '../../../../common/widgets/app_buttons.dart';
import '../../../../common/widgets/app_card.dart';
import '../../../../common/widgets/app_text_field.dart';
import '../../../../common/widgets/section_title.dart';
import '../../../../common/widgets/select_row.dart';
import '../../../../common/widgets/style_radio_list.dart';
import '../../../plan/application/providers/plan_provider.dart';
import '../viewmodel/diary_create_view_model.dart';
import '../../../plan/presentation/widgets/usage_limit_guidance.dart';
import '../../../memo/domain/entities/memo.dart';
import '../../../share/domain/entities/shared_post.dart';
import '../../../tutorial/application/tutorial_providers.dart';
import '../../../tutorial/domain/tutorial_step.dart';
import '../../../tutorial/presentation/tutorial_runner.dart';
import '../providers/diary_create_provider.dart';
import 'diary_result_screen.dart';
import 'generate_flow.dart';
import 'memo_select_page.dart';
import 'post_select_page.dart';
import 'timeline_select_page.dart';
import 'widgets/diary_period_text.dart';
import 'widgets/photo_selection_card.dart';
import 'widgets/token_shortage_dialog.dart';
import '../../domain/entities/diary_style.dart';
import '../../domain/entities/timeline_selection.dart';
import 'widgets/length_field.dart';
import '../../domain/services/token_estimator.dart';

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

  // 「自分で指定」の、書き方の指示
  final _customController = TextEditingController();

  // dispose()で使うため、画面を作るときに取っておく(dispose()の中で初めて読むと、すでに破棄されている)
  late final DiaryCreateViewModel _viewModel;

  // チュートリアルで明るくする部品
  final _dateKey = GlobalKey();
  final _periodKey = GlobalKey();
  final _usageKey = GlobalKey();
  final _modelKey = GlobalKey();
  final _photoKey = GlobalKey();
  final _sourcesKey = GlobalKey();
  final _styleKey = GlobalKey();
  final _lengthKey = GlobalKey();
  final _noteKey = GlobalKey();
  final _generateKey = GlobalKey();

  // この画面のチュートリアルの印(見たかどうかを覚えるときの名前)
  static const _tutorialId = 'diary_ai';

  @override
  void dispose() {
    // 「自分で指定」に書いた指示は、画面を離れたら消す
    final viewModel = _viewModel;
    Future.microtask(viewModel.clearDiaryCustom);

    _customController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();

    _viewModel = ref.read(diaryCreateProvider.notifier);

    // この画面を開いたときに、選んだ日のXの投稿と行動履歴を読み込む
    Future.microtask(() {
      ref.read(diaryCreateProvider.notifier).loadSources();

      // 前回選んだ書き方を戻す
      ref.read(diaryCreateProvider.notifier).loadDiaryStyle();

      // 今月の使用量を取得する
      ref.read(usageProvider.notifier).refresh();
    });

    WidgetsBinding.instance.addPostFrameCallback((_) => _showTutorialOnce());
  }

  // 上から順に、部品を1つずつ説明する(初めて表示したときだけ)
  Future<void> _showTutorialOnce() async {
    final store = ref.read(tutorialSeenStoreProvider);
    if (await store.hasSeen(_tutorialId)) return;
    if (!mounted) return;

    await showTutorial(context, [
      TutorialStep(target: _dateKey, title: "日記の日付", body: "作成する日記の日付を選びます。"),
      TutorialStep(
        target: _periodKey,
        title: "日記にする期間",
        body: "いつからいつまでの出来事を日記にするかを選びます。",
      ),
      TutorialStep(
        target: _modelKey,
        title: "使用するAI",
        body: "日記を書いてもらうAIを選択します。\n「違いを見る」をタップすると、詳細を確認できます。",
      ),
      TutorialStep(
        target: _usageKey,
        title: "トークン使用量",
        body:
            "今月の使用量と、使える上限が表示されます。\n"
            "毎月の無料枠が足りなくなったときは、設定の「ポイント・ゲーム」から、続けて使う方法を確認できます。",
      ),
      TutorialStep(
        target: _photoKey,
        title: "写真",
        body:
            "AIに渡す写真を選びます。この写真をもとにAIが日記を書きます。\n選んだ写真は、AIのサービスに送信されます。\n住所や書類など、個人情報が写っているものは、選ばないでください。\n詳しくは、プライバシーポリシーをご確認ください。",
      ),
      TutorialStep(
        target: _sourcesKey,
        title: "Xの投稿・ひとこと・行動履歴",
        body:
            "AIに日記を書いてもらう際に渡すデータを選びます。\n選んだものは、AIのサービスに送信されます。\n行動履歴には、自宅など場所の情報が含まれます。\n個人情報などが載っているものは、選ばないでください。",
      ),
      TutorialStep(
        target: _styleKey,
        title: "書き方",
        body: "AIに日記を書いてもらう際の書き方を選びます。\nブログ風や箇条書きなどのほかに、自分で指定することもできます。",
        // 縦に長いので、上端に置いて、吹き出しを下に出す
        scrollAlignment: 0,
      ),
      TutorialStep(
        target: _lengthKey,
        title: "文字数の目安",
        body: "日記の長さの目安を指定できます。指定しなくても、作成できます。",
      ),
      TutorialStep(
        target: _noteKey,
        title: "AIに追加で伝えたいこと",
        body: "その日の出来事や、書き方のこだわりなどを追加でAIに伝えられます。",
        bubbleAbove: true,
      ),
      TutorialStep(
        target: _generateKey,
        title: "日記を書いてもらう",
        body: "AIが日記の作成を開始します。\n消費トークンの目安が残り使用可能トークン数を上回っている場合は作成は出来ません。",
        bubbleAbove: true,
      ),
    ]);

    await store.markSeen(_tutorialId);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(diaryCreateProvider);
    final viewModel = ref.read(diaryCreateProvider.notifier);
    final planType = ref.watch(planTypeProvider);
    final usage = ref.watch(usageProvider);
    final model = ref.watch(aiModelProvider);
    final isExceeded = usage?.isExceeded ?? false;

    final canGenerate =
        !(state.isLoadingSources ||
            isExceeded ||
            (state.diaryStyle == DiaryStyle.custom &&
                state.diaryCustom.trim().isEmpty));

    return Scaffold(
      appBar: AppBar(title: Text("${model.label}に書いてもらう")),
      // 画面の下部に、バナー広告を表示する(読み込めたときだけ、白い帯で出る)
      bottomNavigationBar: const SafeArea(child: BannerAdView(band: true)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
        // 画面の外にある部品も、チュートリアルで場所を取れるよう、先に作っておく
        scrollCacheExtent: const ScrollCacheExtent.pixels(6000),
        children: [
          // ---------- いつの日記か
          const SectionTitle("いつの日記？"),
          AppCard(
            child: Column(
              children: [
                // 何月何日の日記を書くか(1日だけ)
                KeyedSubtree(
                  key: _dateKey,
                  child: SelectRow(
                    icon: Icons.calendar_today_outlined,
                    label: "日記の日付",
                    value: dateWithWeekday(state.startDate),
                    onTap: () => _selectDiaryDate(context, state),
                  ),
                ),
                const RowDivider(),
                // AIに渡す情報の期間(プランに関わらず、複数日を選べる。初めは、日記の日付と同じ1日)
                KeyedSubtree(
                  key: _periodKey,
                  child: SelectRow(
                    icon: Icons.date_range_outlined,
                    label: "日記にする期間",
                    value: state.aiStartDate == state.aiEndDate
                        ? dateWithWeekday(state.aiStartDate)
                        : DiaryPeriodText.format(
                            state.aiStartDate,
                            state.aiEndDate,
                          ),
                    onTap: () => _selectPeriod(context, state),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // ---------- 使うAIと、今月の使用量(上限に達している場合は、使えるようになる時期を伝える)
          AiSelectCard(
            usage: usage,
            modelKey: _modelKey,
            usageKey: _usageKey,
            usageExtra: isExceeded
                ? UsageLimitGuidance(isPaid: planType.isPaid)
                : null,
          ),
          const SizedBox(height: 24),

          // ---------- 日記の材料
          const SectionTitle("日記の材料", trailing: "使える材料だけが反映されます"),
          AppCard(
            child: Column(
              children: [
                // AIに渡す写真。初めは日記の日付の月の写真を表示し、年と月を変えて、ほかの写真も選べる
                KeyedSubtree(
                  key: _photoKey,
                  child: PhotoSelectionRows(
                    photos: state.aiPhotos,
                    from: state.aiStartDate,
                    // 対象期間の最終日の終わりまで
                    to: DateTime(
                      state.aiEndDate.year,
                      state.aiEndDate.month,
                      state.aiEndDate.day + 1,
                    ),
                    onChanged: viewModel.setAiPhotos,
                  ),
                ),
                const RowDivider(),
                KeyedSubtree(
                  key: _sourcesKey,
                  child: Column(
                    children: [
                      SelectRow(
                        icon: Icons.chat_bubble_outline,
                        label: "Xの投稿",
                        value: _selectionText(
                          isLoading: state.isLoadingSources,
                          total: state.posts.length,
                          selected: state.selectedPosts.length,
                          emptyText: "この日の投稿はありません",
                        ),
                        trailing: _loadingOrNull(state.isLoadingSources),
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
                      const RowDivider(),
                      SelectRow(
                        icon: Icons.edit_note,
                        label: "ひとことメモ",
                        value: _selectionText(
                          isLoading: state.isLoadingSources,
                          total: state.memos.length,
                          selected: state.selectedMemos.length,
                          emptyText: "この日のメモはありません",
                        ),
                        trailing: _loadingOrNull(state.isLoadingSources),
                        enabled: state.memos.isNotEmpty,
                        onTap: () async {
                          final memos = await Navigator.of(context)
                              .push<List<Memo>>(
                                MaterialPageRoute(
                                  fullscreenDialog: true,
                                  builder: (context) => MemoSelectPage(
                                    memos: state.memos,
                                    initialSelection: state.selectedMemos,
                                  ),
                                ),
                              );

                          if (memos != null) {
                            viewModel.setSelectedMemos(memos);
                          }
                        },
                      ),
                      const RowDivider(),
                      SelectRow(
                        icon: Icons.timeline,
                        label: "行動履歴",
                        value:
                            _selectionText(
                              isLoading: state.isLoadingSources,
                              total: state.timeline.length,
                              selected: state.selectedTimeline.length,
                              emptyText: "この日の行動履歴はありません",
                            ) +
                            // 住所を送るときは、一覧でも分かるようにする
                            (state.timelineAddressStays.isEmpty
                                ? ""
                                : "\n住所も送る: ${state.timelineAddressStays.length}件"),
                        trailing: _loadingOrNull(state.isLoadingSources),
                        enabled: state.timeline.isNotEmpty,
                        onTap: () async {
                          final selection = await Navigator.of(context)
                              .push<TimelineSelection>(
                                MaterialPageRoute(
                                  fullscreenDialog: true,
                                  builder: (context) => TimelineSelectPage(
                                    items: state.timeline,
                                    initialSelection: state.selectedTimeline,
                                    initialAddressStays:
                                        state.timelineAddressStays,
                                  ),
                                ),
                              );

                          if (selection != null) {
                            viewModel.setSelectedTimeline(
                              selection.items,
                              addressStays: selection.addressStays,
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // ---------- 書き方(日記の期間に関わらず、同じ選択肢)
          Column(
            key: _styleKey,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionTitle("書き方"),
              StyleRadioList<DiaryStyle>(
                values: DiaryStyle.values,
                selected: state.diaryStyle,
                label: (style) => style.label,
                description: (style) => style.description,
                onSelected: viewModel.setDiaryStyle,
              ),
            ],
          ),
          if (state.diaryStyle == DiaryStyle.custom) ...[
            const SizedBox(height: 16),
            AppTextField(
              controller: _customController,
              label: "どんな書き方にしたいか",
              hintText: "例: 食べたものを中心に、です・ます調で、300文字くらいで書いてほしい",
              height: 120,
              onChanged: viewModel.setDiaryCustom,
            ),
          ],
          const SizedBox(height: 24),

          // ---------- 文字数の目安(任意)
          KeyedSubtree(
            key: _lengthKey,
            child: LengthField(
              initialChars: state.diaryLengthChars,
              hintExample: 400,
              onChanged: viewModel.setDiaryLength,
            ),
          ),
          const SizedBox(height: 16),

          // ---------- AIに追加で伝えたいこと
          AppTextField(
            key: _noteKey,
            controller: _noteController,
            label: "${model.label}に追加で伝えたいこと",
            hintText: "例：楽しかった気持ちを中心に",
            height: 120,
            onChanged: viewModel.setAiNote,
          ),
          const SizedBox(height: 24),

          // ---------- 生成
          PrimaryButton(
            key: _generateKey,
            icon: Icons.auto_awesome,
            label: "${model.label}に日記を書いてもらう",
            // 読み込みが終わるまでは、選択内容が確定しないため押せないようにする
            // 今月の使用量の上限に達している場合も、押せない
            // 「自分で指定」は、書き方を書くまでは押せない
            onPressed: canGenerate ? () => _generate(context) : null,
          ),
          if (usage != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                "消費トークンの目安 約${formatTokens(_estimate(state))}"
                "（残り ${formatTokens(usage.remainingTokens)}）",
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12, color: AppColors.textSub),
              ),
            ),
        ],
      ),
    );
  }

  // リワード広告を見たあとに、AIに日記を書いてもらう
  Future<void> _generate(BuildContext context) async {
    final ok = await confirmBeforeGenerate(
      context,
      ref,
      estimatedTokens: _estimate(ref.read(diaryCreateProvider)),
    );

    if (!ok || !context.mounted) return;

    ref.read(diaryCreateProvider.notifier).generateDiary();

    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => const DiaryResultScreen()));
  }

  // 選んだ情報から求めた、消費トークンの目安
  int _estimate(DiaryCreateState state) {
    return TokenEstimator.estimate(
      note: state.aiNote,
      timeline: state.selectedTimeline,
      timelineAddressStays: state.timelineAddressStays,
      posts: state.selectedPosts,
      memos: state.selectedMemos,
      photoCount: state.aiPhotos.length,
      photos: state.aiPhotos,
      model: ref.read(aiModelProvider),
      lengthChars: state.diaryLengthChars,
    );
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

  // AIに渡す情報の期間を選ぶ
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
      helpText: "日記にする期間",
    );

    if (range != null) {
      final viewModel = ref.read(diaryCreateProvider.notifier);
      viewModel.setAiDateRange(range.start, range.end);

      // 期間が変わると、AIに渡せる情報も変わるため、読み込み直す
      await viewModel.loadSources();
    }
  }

  // 読み込み中は、右の矢印の代わりに、くるくるを出す(読み込みが終わったら、矢印のまま)
  Widget? _loadingOrNull(bool isLoading) {
    if (!isLoading) return null;

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
