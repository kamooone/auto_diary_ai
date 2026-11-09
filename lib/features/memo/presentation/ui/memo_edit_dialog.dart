import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../diary_create/domain/entities/photo.dart';
import '../../../diary_create/presentation/ui/widgets/photo_selection_card.dart';
import '../../application/providers/memo_providers.dart';
import '../../domain/entities/memo.dart';

/// ひとことメモを追加・修正するダイアログ
///
/// [memo]を渡すと修正、渡さないと追加。保存・修正できたときは、一覧を読み込み直す
Future<void> showMemoEditDialog(
  BuildContext context, {
  Memo? memo,
}) {
  return showDialog<void>(
    context: context,
    builder: (context) => _MemoEditDialog(memo: memo),
  );
}

class _MemoEditDialog extends ConsumerStatefulWidget {
  const _MemoEditDialog({this.memo});

  final Memo? memo;

  @override
  ConsumerState<_MemoEditDialog> createState() => _MemoEditDialogState();
}

class _MemoEditDialogState extends ConsumerState<_MemoEditDialog> {
  late final _controller = TextEditingController(text: widget.memo?.text ?? '');

  // 追加したときの時刻(あとから変えられる)
  late DateTime _createdAt = widget.memo?.createdAt ?? DateTime.now();

  late List<Photo> _photos = [
    for (final id in widget.memo?.photoIds ?? const <String>[])
      Photo(id: id, createdAt: _createdAt),
  ];

  var _isSaving = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  static String _two(int n) => n.toString().padLeft(2, '0');

  String get _dateText =>
      "${_createdAt.year}/${_createdAt.month}/${_createdAt.day} "
      "${_two(_createdAt.hour)}:${_two(_createdAt.minute)}";

  Future<void> _pickDateTime() async {
    final now = DateTime.now();

    final date = await showDatePicker(
      context: context,
      initialDate: _createdAt,
      firstDate: DateTime(2000),
      lastDate: DateTime(now.year + 1, 12, 31),
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_createdAt),
    );
    if (time == null || !mounted) return;

    setState(() {
      _createdAt = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  Future<void> _save() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _isSaving) return;

    setState(() => _isSaving = true);

    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final repository = ref.read(memoRepositoryProvider);

    final saved = Memo(
      id: widget.memo?.id,
      text: text,
      createdAt: _createdAt,
      photoIds: [for (final photo in _photos) photo.id],
    );

    try {
      if (saved.id == null) {
        await repository.save(saved);
      } else {
        await repository.update(saved);
      }
    } catch (e) {
      debugPrint(e.toString());

      if (!mounted) return;
      setState(() => _isSaving = false);
      messenger.showSnackBar(const SnackBar(content: Text("保存に失敗しました")));
      return;
    }

    ref.invalidate(allMemosProvider);
    navigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.memo != null;

    return AlertDialog(
      title: Text(isEditing ? "ひとことメモを修正" : "ひとことメモを追加"),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _controller,
                autofocus: true,
                maxLength: Memo.maxLength,
                minLines: 3,
                maxLines: 6,
                keyboardType: TextInputType.multiline,
                decoration: const InputDecoration(
                  hintText: "今日のできごとや気持ちを、ひとこと",
                  border: OutlineInputBorder(),
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 4),
              ListTile(
                contentPadding: EdgeInsets.zero,
                dense: true,
                leading: const Icon(Icons.schedule),
                title: Text(_dateText),
                trailing: const Text("変更"),
                onTap: _pickDateTime,
              ),
              // 写真は、撮影日に関係なく選べる(日記の編集と同じ)
              PhotoSelectionCard(
                photos: _photos,
                onChanged: (photos) => setState(() => _photos = photos),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text("キャンセル"),
        ),
        FilledButton(
          onPressed: _controller.text.trim().isEmpty || _isSaving ? null : _save,
          child: Text(isEditing ? "保存" : "追加"),
        ),
      ],
    );
  }
}
