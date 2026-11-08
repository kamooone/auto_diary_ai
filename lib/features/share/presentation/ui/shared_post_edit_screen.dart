import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../application/providers/share_providers.dart';
import '../../domain/entities/shared_post.dart';
import '../formatters/shared_post_format.dart';
import 'shared_post_list_screen.dart';

/// Xの投稿の内容と日時を修正する画面
/// 修正または削除した場合は、trueを返して閉じる
class SharedPostEditScreen extends ConsumerStatefulWidget {
  const SharedPostEditScreen({super.key, required this.post});

  final SharedPost post;

  @override
  ConsumerState<SharedPostEditScreen> createState() =>
      _SharedPostEditScreenState();
}

class _SharedPostEditScreenState extends ConsumerState<SharedPostEditScreen> {
  late final _textController = TextEditingController(text: widget.post.text);
  late DateTime _receivedAt = widget.post.receivedAt;

  bool _isSaving = false;

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  // 本文か日時を変えているか
  bool get _isChanged =>
      _textController.text != widget.post.text ||
      _receivedAt != widget.post.receivedAt;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("投稿を編集"),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: "削除",
            onPressed: _isSaving ? null : _delete,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _textController,
            decoration: const InputDecoration(
              labelText: "投稿の内容",
              border: OutlineInputBorder(),
              alignLabelWithHint: true,
            ),
            keyboardType: TextInputType.multiline,
            minLines: 6,
            maxLines: null,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.calendar_today),
                  title: const Text("日付"),
                  subtitle: Text(SharedPostFormat.date(_receivedAt)),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: _pickDate,
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.access_time),
                  title: const Text("時刻"),
                  subtitle: Text(SharedPostFormat.time(_receivedAt)),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: _pickTime,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // URLは変更できない
          Text("URL", style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 2),
          SelectableText(widget.post.url),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: ElevatedButton.icon(
            onPressed: _isChanged && !_isSaving ? _save : null,
            icon: const Icon(Icons.save),
            label: const Text("保存する"),
          ),
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();

    final picked = await showDatePicker(
      context: context,
      initialDate: _receivedAt,
      firstDate: DateTime(2000),
      // 未来の日付は選べない
      lastDate: DateTime(now.year, now.month, now.day),
    );

    if (picked == null) return;

    setState(() {
      _receivedAt = SharedPostFormat.combine(
        picked,
        TimeOfDay.fromDateTime(_receivedAt),
      );
    });
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_receivedAt),
    );

    if (picked == null) return;

    setState(() {
      _receivedAt = SharedPostFormat.combine(_receivedAt, picked);
    });
  }

  Future<void> _save() async {
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    if (_receivedAt.isAfter(DateTime.now())) {
      messenger.showSnackBar(
        const SnackBar(content: Text("未来の日時は指定できません")),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      await ref.read(updateSharedPostUseCaseProvider).execute(
            widget.post,
            text: _textController.text,
            receivedAt: _receivedAt,
          );

      navigator.pop(true);
    } catch (_) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      messenger.showSnackBar(
        const SnackBar(content: Text("保存できませんでした")),
      );
    }
  }

  Future<void> _delete() async {
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    final confirmed = await confirmDeleteSharedPost(context, widget.post);
    if (!confirmed) return;

    setState(() => _isSaving = true);

    try {
      await ref.read(deleteSharedPostUseCaseProvider).execute(widget.post);
      navigator.pop(true);
    } catch (_) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      messenger.showSnackBar(
        const SnackBar(content: Text("削除できませんでした")),
      );
    }
  }
}
