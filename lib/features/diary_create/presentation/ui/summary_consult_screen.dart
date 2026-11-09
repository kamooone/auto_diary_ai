import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../ads/presentation/banner_ad_view.dart';
import '../../../ai/application/providers/ai_model_provider.dart';
import '../../../diary/domain/entities/diary.dart';
import '../../../plan/application/providers/plan_provider.dart';
import '../../../plan/domain/entities/usage_info.dart';
import '../../domain/services/consult_message.dart';
import '../viewmodel/summary_consult_view_model.dart';
import 'widgets/token_shortage_dialog.dart';

/// 「日記を1つにする」の書き方を、AIとチャットで相談する画面
///
/// AIの提案の「これでいいですか？」を押すと、その書き方の指示を返して閉じる。
/// 画面を閉じると、会話はすべて消える
class SummaryConsultScreen extends ConsumerStatefulWidget {
  const SummaryConsultScreen({super.key, required this.diaries});

  final List<Diary> diaries;

  @override
  ConsumerState<SummaryConsultScreen> createState() =>
      _SummaryConsultScreenState();
}

class _SummaryConsultScreenState extends ConsumerState<SummaryConsultScreen> {
  final _controller = TextEditingController();
  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();

    // 開いたらすぐ、日記の内容を送って、おすすめを聞く
    Future.microtask(
      () => ref.read(summaryConsultProvider.notifier).start(widget.diaries),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(summaryConsultProvider);
    final usage = ref.watch(usageProvider);
    final model = ref.watch(aiModelProvider);
    final isExceeded = usage?.isExceeded ?? false;

    // 新しい発言が増えたら、いちばん下まで送る
    ref.listen(summaryConsultProvider, (previous, next) {
      if (previous?.messages.length != next.messages.length ||
          previous?.isSending != next.isSending) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!_scroll.hasClients) return;
          _scroll.animateTo(
            _scroll.position.maxScrollExtent,
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOut,
          );
        });
      }
    });

    return Scaffold(
      appBar: AppBar(title: Text("${model.label}に構成を相談")),
      body: Column(
        children: [
          // 入力欄や送信ボタンから離して、いちばん上に置く
          const BannerAdView(),
          _usageBar(context, state, usage),
          Expanded(
            child: ListView(
              controller: _scroll,
              padding: const EdgeInsets.all(16),
              children: [
                for (final message in state.messages) _bubble(context, message),
                if (state.isSending) _typing(context),
                if (state.errorMessage != null) _error(context, state),
              ],
            ),
          ),
          _inputBar(context, state, isExceeded),
        ],
      ),
    );
  }

  // 今月の使用量(累計)と、この相談で使ったトークンの合計
  Widget _usageBar(
    BuildContext context,
    SummaryConsultState state,
    UsageInfo? usage,
  ) {
    final theme = Theme.of(context);
    final consultTokens = state.messages.fold<int>(
      0,
      (sum, e) => sum + (e.tokens ?? 0),
    );

    final parts = [
      if (usage != null)
        "今月の使用量 ${formatTokens(usage.usedTokens)} / ${formatTokens(usage.limitTokens)} トークン"
            "(残り ${formatTokens(usage.remainingTokens)})"
      else
        "今月の使用量を取得できていません",
      if (consultTokens > 0) "この相談で 約${formatTokens(consultTokens)} トークン",
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      color: theme.colorScheme.surfaceContainerHighest,
      child: Text(
        parts.join("\n"),
        style: theme.textTheme.bodySmall,
      ),
    );
  }

  Widget _bubble(BuildContext context, ConsultMessage message) {
    final scheme = Theme.of(context).colorScheme;
    final fromUser = message.fromUser;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: fromUser
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.85,
            ),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: fromUser
                  ? scheme.primaryContainer
                  : scheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
            ),
            child: SelectableText(message.text),
          ),
          if (message.tokens != null)
            Padding(
              padding: const EdgeInsets.only(top: 2, left: 4),
              child: Text(
                "このやり取りで 約${formatTokens(message.tokens!)} トークン",
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          if (message.proposal != null) ...[
            const SizedBox(height: 8),
            _proposal(context, message.proposal!),
          ],
        ],
      ),
    );
  }

  // AIが提案した書き方の指示と、それを使うボタン
  Widget _proposal(BuildContext context, String proposal) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.85,
      ),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: scheme.primary),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("提案する書き方", style: Theme.of(context).textTheme.labelMedium),
          const SizedBox(height: 4),
          SelectableText(proposal),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton(
              // 「自分で指定」の記入欄に入れて、相談を終える(会話は消える)
              onPressed: () => Navigator.of(context).pop(proposal),
              child: const Text("これでいいですか？(この書き方を使う)"),
            ),
          ),
        ],
      ),
    );
  }

  Widget _typing(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: 8),
          Text("${ref.watch(aiModelProvider).label}が考えています…"),
        ],
      ),
    );
  }

  Widget _error(BuildContext context, SummaryConsultState state) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              state.errorMessage!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
          TextButton(
            onPressed: ref.read(summaryConsultProvider.notifier).retry,
            child: const Text("もう一度送る"),
          ),
        ],
      ),
    );
  }

  Widget _inputBar(
    BuildContext context,
    SummaryConsultState state,
    bool isExceeded,
  ) {
    // 最初の返答が来るまでは、発言できない。使用量の上限に達している場合も、送れない
    final hasReply = state.messages.any((e) => !e.fromUser);
    final enabled = hasReply && !state.isSending && !isExceeded;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isExceeded)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  "今月のAIの使用量の上限に達したため、送れません",
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    enabled: enabled,
                    decoration: InputDecoration(
                      hintText: "${ref.watch(aiModelProvider).label}に伝えたいこと(例: もっと短くしたい)",
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    keyboardType: TextInputType.multiline,
                    minLines: 1,
                    maxLines: 4,
                  ),
                ),
                IconButton(
                  onPressed: enabled ? _send : null,
                  icon: const Icon(Icons.send),
                  tooltip: "送信",
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _send() {
    final text = _controller.text;
    if (text.trim().isEmpty) return;

    _controller.clear();
    ref.read(summaryConsultProvider.notifier).send(text);
  }
}
