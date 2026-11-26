import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show ScrollCacheExtent;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../ads/presentation/banner_ad_view.dart';
import '../../../diary/application/providers/diary_providers.dart';
import '../../../diary/domain/entities/diary.dart';
import '../../../plan/application/providers/plan_provider.dart';
import '../../../ai/application/providers/ai_model_provider.dart';
import '../../../ai/presentation/widgets/ai_select_card.dart';
import '../../../plan/domain/entities/usage_info.dart';
import '../../../../common/constants/app_colors.dart';
import '../../../../common/widgets/app_buttons.dart';
import '../../../../common/widgets/app_card.dart';
import '../../../../common/widgets/app_text_field.dart';
import '../../../../common/widgets/section_title.dart';
import '../../../../common/widgets/select_row.dart';
import '../../../../common/widgets/style_radio_list.dart';
import '../../../tutorial/application/tutorial_providers.dart';
import '../../../tutorial/domain/tutorial_step.dart';
import '../../../tutorial/presentation/tutorial_runner.dart';
import '../../domain/entities/summary_style.dart';
import '../../domain/services/summary_text.dart';
import '../../domain/services/token_estimator.dart';
import '../providers/diary_create_provider.dart';
import '../viewmodel/diary_create_view_model.dart';
import 'diary_result_screen.dart';
import 'diary_select_page.dart';
import 'generate_flow.dart';
import 'summary_consult_screen.dart';
import 'widgets/length_field.dart';
import 'widgets/token_shortage_dialog.dart';

/// 作成済みの日記を選んで、AIに1つの日記(月の振り返り・1年の振り返りなど)にしてもらう画面
class SummaryDiaryScreen extends ConsumerStatefulWidget {
  const SummaryDiaryScreen({super.key});

  @override
  ConsumerState<SummaryDiaryScreen> createState() => _SummaryDiaryScreenState();
}

class _SummaryDiaryScreenState extends ConsumerState<SummaryDiaryScreen> {
  late final _noteController = TextEditingController(
    text: ref.read(diaryCreateProvider).aiNote,
  );

  // 「自分で指定」の、書き方の指示
  final _customController = TextEditingController();

  // dispose()で使うため、画面を作るときに取っておく(dispose()の中で初めて読むと、すでに破棄されている)
  late final DiaryCreateViewModel _viewModel;

  // チュートリアルで明るくする部品
  final _usageKey = GlobalKey();
  final _modelKey = GlobalKey();
  final _diariesKey = GlobalKey();
  final _styleKey = GlobalKey();
  final _consultKey = GlobalKey();
  final _lengthKey = GlobalKey();
  final _noteKey = GlobalKey();
  final _generateKey = GlobalKey();

  // この画面のチュートリアルの印(見たかどうかを覚えるときの名前)
  static const _tutorialId = 'summary_diary';

  @override
  void initState() {
    super.initState();

    _viewModel = ref.read(diaryCreateProvider.notifier);

    Future.microtask(() async {
      // 今月の使用量を取得する
      ref.read(usageProvider.notifier).refresh();

      // 前回選んだ書き方を戻す
      await _viewModel.loadSummaryStyle();
    });

    WidgetsBinding.instance.addPostFrameCallback((_) => _showTutorialOnce());
  }

  // 上から順に、部品を1つずつ説明する(初めて表示したときだけ)
  Future<void> _showTutorialOnce() async {
    final store = ref.read(tutorialSeenStoreProvider);
    if (await store.hasSeen(_tutorialId)) return;
    if (!mounted) return;

    await showTutorial(context, [
      TutorialStep(
        target: _diariesKey,
        title: "振り返りに使う日記",
        body:
            "作成済みの日記から、振り返りに使う日記を選びます。\n2件以上選ぶと作成できます。1か月分や1年分も選べます。\n選んだ日記の内容は、AIのサービスに送信されます(「日記を連結させる」は、AIを使わないので送信されません)。",
      ),
      TutorialStep(
        target: _modelKey,
        title: "使用するAI",
        body: "振り返りを書いてもらうAIを選択します。\n「違いを見る」をタップすると、詳細を確認できます。",
      ),
      TutorialStep(
        target: _usageKey,
        title: "トークン使用量",
        body:
            "今月の使用量と、使える上限が表示されます。\n"
            "毎月の無料枠が足りなくなったときは、設定の「ポイント・ゲーム」から、続けて使う方法を確認できます。",
      ),
      TutorialStep(
        target: _styleKey,
        title: "書き方",
        body:
            "振り返りの書き方を選びます。\nブログ風や箇条書きなどのほかに、自分で指定することもできます。\n「日記を連結させる」は、AIを使わずに日記をつなげるので、トークンを使いません。",
        // 縦に長く、説明も長いので、下端に置いて、吹き出しを上に出す
        bubbleAbove: true,
        scrollAlignment: 1,
      ),
      TutorialStep(
        target: _consultKey,
        title: "構成を相談する",
        body: "選んだ日記から、どんな書き方がよいかをAIに相談できます。",
      ),
      TutorialStep(
        target: _lengthKey,
        title: "文字数の目安",
        body: "振り返りの長さの目安を指定できます。指定しなくても、作成できます。",
      ),
      TutorialStep(
        target: _noteKey,
        title: "AIに追加で伝えたいこと",
        body: "どんな振り返りにしたいかや、書き方のこだわりなどを、追加でAIに伝えられます。",
        bubbleAbove: true,
      ),
      TutorialStep(
        target: _generateKey,
        title: "振り返りを作成する",
        body: "AIが振り返りの作成を開始します。\n消費トークンの目安が残り使用可能トークン数を上回っている場合は作成は出来ません。",
        bubbleAbove: true,
      ),
    ]);

    await store.markSeen(_tutorialId);
  }

  @override
  void dispose() {
    // 「自分で指定」に書いた指示は、画面を離れたら消す
    final viewModel = _viewModel;
    Future.microtask(viewModel.clearSummaryCustom);

    _noteController.dispose();
    _customController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(diaryCreateProvider);
    final viewModel = ref.read(diaryCreateProvider.notifier);
    final diaries = ref.watch(diariesProvider).valueOrNull ?? const <Diary>[];
    final usage = ref.watch(usageProvider);
    final model = ref.watch(aiModelProvider);
    final isExceeded = usage?.isExceeded ?? false;

    final selected = state.summaryDiaries;
    final isTooLong = SummaryText.length(selected) > SummaryText.maxChars;

    // 「自分で指定」は、書き方を書くまでは作れない
    // 日記を連結させるは、AIを使わずにつなげるので、トークンも広告もいらない
    final isJoin = state.summaryStyle == SummaryStyle.chronicle;

    final needsCustom =
        state.summaryStyle == SummaryStyle.custom &&
        state.summaryCustom.trim().isEmpty;

    final canGenerate =
        !(selected.length < SummaryText.minCount ||
            isTooLong ||
            (isExceeded && !isJoin) ||
            needsCustom);

    return Scaffold(
      appBar: AppBar(title: const Text("振り返り作成")),
      // 画面の下部に、バナー広告を表示する(読み込めたときだけ、白い帯で出る)
      bottomNavigationBar: const SafeArea(child: BannerAdView(band: true)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
        // 画面の外にある部品も、チュートリアルで場所を取れるよう、先に作っておく
        scrollCacheExtent: const ScrollCacheExtent.pixels(6000),
        children: [
          // ---------- 振り返りに使う日記
          const SectionTitle("振り返りに使う日記"),
          AppCard(
            key: _diariesKey,
            child: SelectRow(
              icon: Icons.menu_book_outlined,
              label: "選んだ日記",
              value: diaries.isEmpty
                  ? "まだ日記がありません"
                  : "${diaries.length}件中${selected.length}件を選択中",
              enabled: diaries.isNotEmpty,
              onTap: () => _select(context, diaries, selected),
            ),
          ),
          const SizedBox(height: 24),

          // ---------- 使うAIと、今月の使用量
          // AIを使わない「日記を連結させる」では、AIを選ぶ必要がないので、使用量だけを出す
          AiSelectCard(
            usage: usage,
            showModel: !isJoin,
            modelKey: _modelKey,
            usageKey: _usageKey,
          ),
          const SizedBox(height: 24),

          // ---------- 書き方
          Column(
            key: _styleKey,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionTitle("書き方"),
              StyleRadioList<SummaryStyle>(
                values: SummaryStyle.values,
                selected: state.summaryStyle,
                label: (style) => style.label,
                description: (style) => style.description,
                onSelected: viewModel.setSummaryStyle,
              ),
            ],
          ),
          if (state.summaryStyle == SummaryStyle.custom) ...[
            const SizedBox(height: 16),
            AppTextField(
              controller: _customController,
              label: "どんな書き方にしたいか",
              hintText: "例: 仕事の話だけを中心に、です・ます調で、800文字くらいで書いてほしい",
              height: 120,
              onChanged: viewModel.setSummaryCustom,
            ),
          ],
          const SizedBox(height: 24),

          // 選んだ日記を見て、書き方をAIに相談する
          SecondaryButton(
            key: _consultKey,
            icon: Icons.chat_outlined,
            label: "${model.label}に構成を相談する",
            // 1つにするには、2件以上必要なので、それまでは相談もできない
            onPressed: selected.length < SummaryText.minCount || isExceeded
                ? null
                : () => _consult(context, selected),
          ),
          const SizedBox(height: 24),

          // AIを使わない「日記を連結させる」では、伝える相手がいないので出さない
          // 一覧は、1件ずつ短く書く形なので、文字数は指定しない
          if (!isJoin && state.summaryStyle != SummaryStyle.list) ...[
            KeyedSubtree(
              key: _lengthKey,
              child: LengthField(
                initialChars: state.summaryLengthChars,
                hintExample: 1200,
                onChanged: viewModel.setSummaryLength,
              ),
            ),
            const SizedBox(height: 16),
          ],

          if (!isJoin) ...[
            AppTextField(
              key: _noteKey,
              controller: _noteController,
              label: "${model.label}に追加で伝えたいこと",
              hintText: "例：この1年の変化がわかるように。目次をつけて",
              height: 120,
              onChanged: viewModel.setAiNote,
            ),
            const SizedBox(height: 24),
          ],

          // ---------- 作成
          PrimaryButton(
            key: _generateKey,
            icon: Icons.auto_awesome,
            label: isJoin ? "振り返りを作成する" : "${model.label}に振り返りを作成してもらう",
            // 2件以上選ぶまでは押せない。使用量の上限に達している場合も、押せない
            onPressed: canGenerate ? () => _generate(context) : null,
          ),

          // 押せない理由や、トークンの目安は、ボタンのすぐ下に出す
          ..._notes(
            usage: usage,
            state: state,
            selectedCount: selected.length,
            isJoin: isJoin,
            needsCustom: needsCustom,
          ),
        ],
      ),
    );
  }

  // ボタンのすぐ下に、中央そろえで出す、小さな説明
  List<Widget> _notes({
    required UsageInfo? usage,
    required DiaryCreateState state,
    required int selectedCount,
    required bool isJoin,
    required bool needsCustom,
  }) {
    final notes = <String>[
      if (selectedCount < SummaryText.minCount)
        "日記を${SummaryText.minCount}件以上選んでください",
      if (needsCustom) "「自分で指定」を選んだときは、書き方を書いてください",
      if (isJoin && selectedCount > 0)
        "AIを使わないので、トークンは消費しません"
      else if (usage != null && selectedCount > 0)
        "消費トークンの目安 約${formatTokens(_estimate(state))}"
            "（残り ${formatTokens(usage.remainingTokens)}）",
    ];

    return [
      for (final note in notes)
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(
            note,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12, color: AppColors.textSub),
          ),
        ),
    ];
  }

  Future<void> _select(
    BuildContext context,
    List<Diary> diaries,
    List<Diary> selected,
  ) async {
    final result = await Navigator.of(context).push<List<Diary>>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (context) =>
            DiarySelectPage(diaries: diaries, initialSelection: selected),
      ),
    );

    if (result != null) {
      ref.read(diaryCreateProvider.notifier).setSummaryDiaries(result);
    }
  }

  // 日記の全文をAIに送って、書き方を相談する。AIの提案を受け取ったら、「自分で指定」に入れる
  Future<void> _consult(BuildContext context, List<Diary> selected) async {
    final ok = await confirmBeforeConsult(
      context,
      ref,
      estimatedTokens: TokenEstimator.estimateConsult(
        selected,
        model: ref.read(aiModelProvider),
      ),
    );
    if (!ok || !context.mounted) return;

    final proposal = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (context) => SummaryConsultScreen(diaries: selected),
      ),
    );

    if (proposal == null || !mounted) return;

    ref.read(diaryCreateProvider.notifier).applySummaryProposal(proposal);
    _customController.text = proposal;
  }

  Future<void> _generate(BuildContext context) async {
    // AIを使わないときは、確認も広告もなしで、すぐにつなげる
    if (ref.read(diaryCreateProvider).summaryStyle == SummaryStyle.chronicle) {
      ref.read(diaryCreateProvider.notifier).generateSummaryDiary();

      Navigator.of(context).push(
        MaterialPageRoute(builder: (context) => const DiaryResultScreen()),
      );
      return;
    }

    final ok = await confirmBeforeGenerate(
      context,
      ref,
      estimatedTokens: _estimate(ref.read(diaryCreateProvider)),
    );

    if (!ok || !context.mounted) return;

    ref.read(diaryCreateProvider.notifier).generateSummaryDiary();

    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => const DiaryResultScreen()));
  }

  int _estimate(DiaryCreateState state) {
    return TokenEstimator.estimate(
      note: state.aiNote,
      timeline: const [],
      posts: const [],
      photoCount: 0,
      diaries: state.summaryDiaries,
      summaryStyle: state.summaryStyle,
      model: ref.read(aiModelProvider),
      lengthChars: state.summaryStyle == SummaryStyle.list
          ? 0
          : state.summaryLengthChars,
    );
  }
}
