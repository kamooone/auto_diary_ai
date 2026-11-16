import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../common/constants/app_colors.dart';
import '../../../../common/constants/app_sizes.dart';
import '../../application/providers/inquiry_providers.dart';
import '../../domain/entities/inquiry_category.dart';
import '../../domain/entities/inquiry_exception.dart';
import '../../domain/entities/inquiry_limits.dart';
import '../../domain/entities/inquiry_message.dart';

/// お問い合わせの画面。送った内容と、開発者からの返信が、時刻順に並ぶ
class InquiryPage extends ConsumerStatefulWidget {
  const InquiryPage({super.key});

  @override
  ConsumerState<InquiryPage> createState() => _InquiryPageState();
}

class _InquiryPageState extends ConsumerState<InquiryPage> {
  final _controller = TextEditingController();
  var _category = InquiryCategory.bug;
  var _isSending = false;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get _canSend => !_isSending && _controller.text.trim().isNotEmpty;

  Future<void> _send() async {
    setState(() {
      _isSending = true;
      _error = null;
    });

    try {
      await ref
          .read(inquiryRepositoryProvider)
          .send(category: _category, message: _controller.text.trim());
      await ref.read(inquiryStateStoreProvider).markSent();

      // 返信の通知を受けられるよう、この端末の宛先を登録する(失敗しても、送信は成功のまま)
      unawaited(ref.read(pushRegistrarProvider).sync());

      _controller.clear();
      ref.invalidate(inquiryMessagesProvider);
      if (!mounted) return;

      setState(() => _isSending = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("送信しました。ありがとうございます")));
    } on InquiryException catch (e) {
      if (!mounted) return;
      setState(() {
        _isSending = false;
        _error = e.reason == InquiryFailure.tooMany
            ? "送れる件数の上限に達しました。しばらくたってから、もう一度お試しください"
            : "送信できませんでした。通信を確認して、もう一度お試しください";
      });
    }
  }

  // 返信を表示したら、見たことにする(ホーム・設定のお知らせを消す)
  Future<void> _markSeen(List<InquiryMessage> messages) async {
    final replies = messages.where((e) => e.fromDeveloper);
    if (replies.isEmpty) return;

    final newest = replies
        .map((e) => e.createdAt)
        .reduce((a, b) => a.isAfter(b) ? a : b);
    await ref.read(inquiryStateStoreProvider).markSeen(newest);
    ref.invalidate(hasUnreadReplyProvider);
  }

  @override
  Widget build(BuildContext context) {
    final messages = ref.watch(inquiryMessagesProvider);

    ref.listen(inquiryMessagesProvider, (_, next) {
      final data = next.valueOrNull;
      if (data != null) _markSeen(data);
    });

    return Scaffold(
      appBar: AppBar(title: const Text("お問い合わせ")),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: messages.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, _) => const Center(child: Text("やり取りを読み込めませんでした")),
                data: (list) => _MessageList(messages: list),
              ),
            ),
            _Form(
              controller: _controller,
              category: _category,
              error: _error,
              canSend: _canSend,
              isSending: _isSending,
              onCategoryChanged: (value) => setState(() => _category = value),
              onTextChanged: () => setState(() {}),
              onSend: _send,
            ),
          ],
        ),
      ),
    );
  }
}

class _MessageList extends StatelessWidget {
  const _MessageList({required this.messages});

  final List<InquiryMessage> messages;

  @override
  Widget build(BuildContext context) {
    if (messages.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Center(
          child: Text(
            style: TextStyle(
              fontSize: 14,
              height: 1.8,
              color: AppColors.textSub,
            ),
            "不具合のご報告や、ご要望をお送りください。\n\n"
            "いただいた内容は、改善に役立てます。\n"
            "返信がある場合は、この画面に表示されます"
            "(アプリを削除すると、やり取りは見られなくなります)。",
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(AppSizes.space16),
      itemCount: messages.length,
      itemBuilder: (context, index) => _Bubble(message: messages[index]),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.message});

  final InquiryMessage message;

  static String _time(DateTime t) {
    final minute = t.minute.toString().padLeft(2, '0');
    return "${t.month}月${t.day}日 ${t.hour}:$minute";
  }

  @override
  Widget build(BuildContext context) {
    final fromDeveloper = message.fromDeveloper;
    final category = message.category;

    return Align(
      alignment: fromDeveloper ? Alignment.centerLeft : Alignment.centerRight,
      child: Padding(
        padding: const EdgeInsets.only(bottom: AppSizes.space12),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.sizeOf(context).width * 0.78,
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              // 自分は淡いピンク(右下だけ小さい角)、開発者は白に枠(左下だけ小さい角)
              color: fromDeveloper ? AppColors.white : AppColors.pink,
              border: fromDeveloper ? Border.all(color: AppColors.line) : null,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(16),
                topRight: const Radius.circular(16),
                bottomLeft: Radius.circular(fromDeveloper ? 4 : 16),
                bottomRight: Radius.circular(fromDeveloper ? 16 : 4),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fromDeveloper
                      ? "開発者からの返信"
                      : "あなた${category == null ? "" : " ・ ${category.label}"}",
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.navyDark,
                  ),
                ),
                const SizedBox(height: AppSizes.space4),
                Text(
                  message.text,
                  style: const TextStyle(
                    fontSize: 15,
                    height: 1.7,
                    color: AppColors.text,
                  ),
                ),
                const SizedBox(height: AppSizes.space4),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    _time(message.createdAt),
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSub,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Form extends StatelessWidget {
  const _Form({
    required this.controller,
    required this.category,
    required this.error,
    required this.canSend,
    required this.isSending,
    required this.onCategoryChanged,
    required this.onTextChanged,
    required this.onSend,
  });

  final TextEditingController controller;
  final InquiryCategory category;
  final String? error;
  final bool canSend;
  final bool isSending;
  final ValueChanged<InquiryCategory> onCategoryChanged;
  final VoidCallback onTextChanged;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.white,
        border: Border(top: BorderSide(color: AppColors.line)),
      ),
      padding: const EdgeInsets.fromLTRB(
        AppSizes.space16,
        AppSizes.space12,
        AppSizes.space16,
        20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 種類の選択(選んでいるものは、ネイビーにチェック)
          Wrap(
            spacing: AppSizes.space8,
            children: [
              for (final value in InquiryCategory.values)
                _CategoryButton(
                  label: value.label,
                  selected: value == category,
                  onTap: () => onCategoryChanged(value),
                ),
            ],
          ),
          const SizedBox(height: AppSizes.space12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 88),
                  child: TextField(
                    key: const Key('inquiryText'),
                    controller: controller,
                    minLines: 3,
                    maxLines: 5,
                    maxLength: InquiryLimits.maxLength,
                    onChanged: (_) => onTextChanged(),
                    style: const TextStyle(fontSize: 15, color: AppColors.text),
                    decoration: InputDecoration(
                      hintText: "内容を書いてください",
                      hintStyle: const TextStyle(
                        fontSize: 15,
                        color: AppColors.mutedText,
                      ),
                      counterText: '',
                      fillColor: AppColors.pageBackground,
                      contentPadding: const EdgeInsets.all(14),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSizes.space12),
              // 送信(押せるときは濃いオレンジ、押せないときはうすい色)
              Semantics(
                label: '送信',
                button: true,
                excludeSemantics: true,
                child: Material(
                  color: canSend
                      ? AppColors.orangeDark
                      : AppColors.disabledFill,
                  shape: const CircleBorder(),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: canSend ? onSend : null,
                    child: SizedBox(
                      width: 48,
                      height: 48,
                      child: Center(
                        child: isSending
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : Icon(
                                Icons.send_outlined,
                                size: 22,
                                color: canSend
                                    ? AppColors.white
                                    : AppColors.disabledContent,
                              ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          // 文字数
          Padding(
            padding: const EdgeInsets.only(
              left: AppSizes.space4,
              top: AppSizes.space4,
            ),
            child: Text(
              "${controller.text.characters.length} / ${InquiryLimits.maxLength}",
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSub,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
          ),
          if (error != null)
            Padding(
              padding: const EdgeInsets.only(top: AppSizes.space4),
              child: Text(
                error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
        ],
      ),
    );
  }
}

class _CategoryButton extends StatelessWidget {
  const _CategoryButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.white : AppColors.textSub;

    return Semantics(
      inMutuallyExclusiveGroup: true,
      checked: selected,
      button: true,
      child: Material(
        color: selected ? AppColors.navy : AppColors.white,
        shape: StadiumBorder(
          side: selected
              ? BorderSide.none
              : const BorderSide(color: AppColors.line),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Container(
            height: 36,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            alignment: Alignment.center,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (selected) ...[
                  Icon(Icons.check, size: 16, color: color),
                  const SizedBox(width: AppSizes.space4),
                ],
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
