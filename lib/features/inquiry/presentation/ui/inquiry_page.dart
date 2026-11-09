import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

      _controller.clear();
      ref.invalidate(inquiryMessagesProvider);
      if (!mounted) return;

      setState(() => _isSending = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("送信しました。ありがとうございます")),
      );
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

    final newest = replies.map((e) => e.createdAt).reduce(
      (a, b) => a.isAfter(b) ? a : b,
    );
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
                error: (_, _) => const Center(
                  child: Text("やり取りを読み込めませんでした"),
                ),
                data: (list) => _MessageList(messages: list),
              ),
            ),
            const Divider(height: 1),
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
            "不具合のご報告や、ご要望をお送りください。\n\n"
            "いただいた内容は、改善に役立てます。\n"
            "返信がある場合は、この画面に表示されます"
            "(アプリを削除すると、やり取りは見られなくなります)。\n\n"
            "個人情報や、日記の内容は、書かないでください。",
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
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
    final scheme = Theme.of(context).colorScheme;
    final fromDeveloper = message.fromDeveloper;

    return Align(
      alignment: fromDeveloper ? Alignment.centerLeft : Alignment.centerRight,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.8,
        ),
        child: Card(
          color: fromDeveloper
              ? scheme.secondaryContainer
              : scheme.primaryContainer,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fromDeveloper
                      ? "開発者からの返信"
                      : "あなた${message.category == null ? "" : "(${message.category!.label})"}",
                  style: Theme.of(context).textTheme.labelSmall,
                ),
                const SizedBox(height: 4),
                Text(message.text),
                const SizedBox(height: 4),
                Text(
                  _time(message.createdAt),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Colors.grey[600],
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            children: [
              for (final value in InquiryCategory.values)
                ChoiceChip(
                  label: Text(value.label),
                  selected: value == category,
                  onSelected: (_) => onCategoryChanged(value),
                ),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            key: const Key('inquiryText'),
            controller: controller,
            minLines: 2,
            maxLines: 5,
            maxLength: InquiryLimits.maxLength,
            onChanged: (_) => onTextChanged(),
            decoration: const InputDecoration(
              hintText: "内容を書いてください(個人情報や日記の内容は書かないでください)",
              border: OutlineInputBorder(),
            ),
          ),
          if (error != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton(
              onPressed: canSend ? onSend : null,
              child: isSending
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text("送信"),
            ),
          ),
        ],
      ),
    );
  }
}
