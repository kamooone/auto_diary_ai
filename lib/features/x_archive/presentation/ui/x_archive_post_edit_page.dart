import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/providers/x_archive_providers.dart';
import '../../domain/entities/x_archive_post.dart';

/// 取り込んだ投稿の、本文と日時を直す画面
/// 保存したら、trueを返して閉じる
class XArchivePostEditPage extends ConsumerStatefulWidget {
  const XArchivePostEditPage({super.key, required this.post});

  final XArchivePost post;

  @override
  ConsumerState<XArchivePostEditPage> createState() =>
      _XArchivePostEditPageState();
}

class _XArchivePostEditPageState extends ConsumerState<XArchivePostEditPage> {
  // 日時は、日本時間で見せて、日本時間で直す(保存は、これまでどおりUTC)
  static const _jstOffset = Duration(hours: 9);

  late final _textController = TextEditingController(text: widget.post.text);
  late DateTime _jst = widget.post.createdAt.add(_jstOffset);
  bool _saving = false;

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  DateTime get _utc => _jst.subtract(_jstOffset);

  bool get _changed =>
      _textController.text != widget.post.text ||
      _utc != widget.post.createdAt;

  static String _two(int n) => n.toString().padLeft(2, '0');

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(_jst.year, _jst.month, _jst.day),
      firstDate: DateTime(2006),
      lastDate: DateTime(now.year, now.month, now.day),
    );
    if (picked == null) return;
    setState(
      () => _jst = DateTime.utc(
        picked.year,
        picked.month,
        picked.day,
        _jst.hour,
        _jst.minute,
      ),
    );
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: _jst.hour, minute: _jst.minute),
    );
    if (picked == null) return;
    setState(
      () => _jst = DateTime.utc(
        _jst.year,
        _jst.month,
        _jst.day,
        picked.hour,
        picked.minute,
      ),
    );
  }

  Future<void> _save() async {
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    if (_utc.isAfter(DateTime.now().toUtc())) {
      messenger.showSnackBar(const SnackBar(content: Text('未来の日時は指定できません')));
      return;
    }

    setState(() => _saving = true);
    try {
      await ref.read(xArchiveRepositoryProvider).updateContent(
            widget.post.tweetId,
            text: _textController.text,
            createdAt: _utc,
          );
      navigator.pop(true);
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      messenger.showSnackBar(const SnackBar(content: Text('保存できませんでした')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('投稿を編集')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _textController,
            decoration: const InputDecoration(
              labelText: '投稿の内容',
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
                  title: const Text('日付'),
                  subtitle: Text('${_jst.year}/${_two(_jst.month)}/${_two(_jst.day)}'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: _pickDate,
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.access_time),
                  title: const Text('時刻'),
                  subtitle: Text('${_two(_jst.hour)}:${_two(_jst.minute)}'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: _pickTime,
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: ElevatedButton.icon(
            onPressed: _changed && !_saving ? _save : null,
            icon: const Icon(Icons.save),
            label: const Text('保存する'),
          ),
        ),
      ),
    );
  }
}
