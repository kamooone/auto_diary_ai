import 'package:flutter/material.dart';

class SharePreviewDialog extends StatefulWidget {
  final String url;
  final String text;

  const SharePreviewDialog({
    super.key,
    required this.url,
    required this.text,
  });

  @override
  State<SharePreviewDialog> createState() => _SharePreviewDialogState();
}

class _SharePreviewDialogState extends State<SharePreviewDialog> {
  DateTime? _selectedDate;

  Future<void> _pickDateTime() async {
    final now = DateTime.now();

    final date = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (!mounted) return;
    if (date == null) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(now),
    );

    if (time == null) return;

    setState(() {
      _selectedDate = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  void _onConfirm() {
    if (_selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('日時を選択してください')),
      );
      return;
    }

    // ダイアログを閉じる + 値を返す
    Navigator.of(context).pop(_selectedDate);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('投稿内容の確認'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'テキスト',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          Text(widget.text.isEmpty ? '(取得できませんでした)' : widget.text),
          const SizedBox(height: 20),

          ElevatedButton(
            onPressed: _pickDateTime,
            child: Text(
              _selectedDate == null
                  ? '日時を選択'
                  : _selectedDate.toString(),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('キャンセル'),
        ),
        ElevatedButton(
          onPressed: _onConfirm,
          child: const Text('OK'),
        ),
      ],
    );
  }
}