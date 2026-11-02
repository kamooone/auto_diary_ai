import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../diary/application/providers/diary_providers.dart';
import '../../../diary/domain/entities/diary.dart';
import '../../../plan/application/providers/plan_provider.dart';
import '../../../plan/presentation/widgets/usage_meter.dart';
import '../../domain/entities/summary_style.dart';
import '../../domain/services/summary_text.dart';
import '../../domain/services/token_estimator.dart';
import '../providers/diary_create_provider.dart';
import '../viewmodel/diary_create_view_model.dart';
import 'diary_result_screen.dart';
import 'diary_select_page.dart';
import 'generate_flow.dart';
import 'summary_consult_screen.dart';
import 'widgets/style_choice_card.dart';
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

  late final _viewModel = ref.read(diaryCreateProvider.notifier);

  @override
  void initState() {
    super.initState();

    Future.microtask(() async {
      // 今月の使用量を取得する
      ref.read(usageProvider.notifier).refresh();

      // 前回選んだ書き方を戻す
      await _viewModel.loadSummaryStyle();
    });
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
    final isExceeded = usage?.isExceeded ?? false;

    final selected = state.summaryDiaries;
    final isTooLong = SummaryText.length(selected) > SummaryText.maxChars;

    // 「自分で指定」は、書き方を書くまでは作れない
    // 日記を連結させるは、AIを使わずにつなげるので、トークンも広告もいらない
    final isJoin = state.summaryStyle == SummaryStyle.chronicle;

    final needsCustom =
        state.summaryStyle == SummaryStyle.custom &&
        state.summaryCustom.trim().isEmpty;

    return Scaffold(
      appBar: AppBar(title: const Text("日記を1つにする")),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            "作成済みの日記を選ぶと、AIが選んだ日記の内容を使って、"
            "1つの日記に書きます。1か月分や1年分の日記を、1つにできます。",
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 12),

          Card(
            child: UsageMeter(usage: usage),
          ),
          const SizedBox(height: 12),

          Card(
            child: ListTile(
              leading: const Icon(Icons.menu_book),
              title: const Text("1つにする日記"),
              subtitle: Text(
                diaries.isEmpty
                    ? "まだ日記がありません"
                    : "${diaries.length}件中${selected.length}件を選択中",
              ),
              trailing: const Icon(Icons.chevron_right),
              enabled: diaries.isNotEmpty,
              onTap: () => _select(context, diaries, selected),
            ),
          ),
          const SizedBox(height: 12),

          // ---------- 書き方
          Text("書き方", style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 4),
          StyleChoiceCard<SummaryStyle>(
            values: SummaryStyle.values,
            selected: state.summaryStyle,
            label: (style) => style.label,
            description: (style) => style.description,
            onSelected: viewModel.setSummaryStyle,
          ),
          if (state.summaryStyle == SummaryStyle.custom) ...[
            const SizedBox(height: 8),
            TextField(
              controller: _customController,
              decoration: const InputDecoration(
                labelText: "どんな書き方にしたいか",
                hintText: "例: 仕事の話だけを中心に、です・ます調で、800文字くらいで書いてほしい",
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
              keyboardType: TextInputType.multiline,
              minLines: 3,
              maxLines: 8,
              onChanged: viewModel.setSummaryCustom,
            ),
          ],
          const SizedBox(height: 8),

          // 選んだ日記を見て、書き方をAIに相談する
          OutlinedButton.icon(
            // 1つにするには、2件以上必要なので、それまでは相談もできない
            onPressed: selected.length < SummaryText.minCount || isExceeded
                ? null
                : () => _consult(context, selected),
            icon: const Icon(Icons.chat_outlined),
            label: const Text("AIに構成を相談する"),
          ),
          const SizedBox(height: 16),

          // AIを使わない「日記を連結させる」では、伝える相手がいないので出さない
          if (!isJoin) ...[
            TextField(
              controller: _noteController,
              decoration: const InputDecoration(
                labelText: "AIに追加で伝えたいこと",
                hintText: "例: 今年1年の振り返りとして、前向きな言葉で締めてほしい",
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
              keyboardType: TextInputType.multiline,
              minLines: 3,
              maxLines: 8,
              onChanged: viewModel.setAiNote,
            ),
            const SizedBox(height: 16),
          ],

          if (selected.length < SummaryText.minCount)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                "日記を${SummaryText.minCount}件以上選んでください",
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          if (needsCustom)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                "「自分で指定」を選んだときは、書き方を書いてください",
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          if (isJoin && selected.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                "AIを使わないので、トークンは消費しません",
                style: Theme.of(context).textTheme.bodySmall,
              ),
            )
          else if (usage != null && selected.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                "消費トークンの目安: 約${formatTokens(_estimate(state))}"
                "(残り ${formatTokens(usage.remainingTokens)})",
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ElevatedButton.icon(
            // 2件以上選ぶまでは押せない。使用量の上限に達している場合も、押せない
            onPressed:
                selected.length < SummaryText.minCount ||
                    isTooLong ||
                    (isExceeded && !isJoin) ||
                    needsCustom
                ? null
                : () => _generate(context),
            icon: const Icon(Icons.auto_awesome),
            label: Text(isJoin ? "日記を1つにする" : "AIに1つにしてもらう"),
          ),
        ],
      ),
    );
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
      estimatedTokens: TokenEstimator.estimateConsult(selected),
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
    );
  }
}
