import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/diary_create_provider.dart';
import '../viewmodel/diary_create_view_model.dart';

/// AIが書いた日記を確認・修正して保存する画面
class DiaryResultScreen extends ConsumerStatefulWidget {
  const DiaryResultScreen({super.key});

  @override
  ConsumerState<DiaryResultScreen> createState() => _DiaryResultScreenState();
}

class _DiaryResultScreenState extends ConsumerState<DiaryResultScreen> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();

  @override
  void initState() {
    super.initState();

    // すでに書き上がっている場合は、その内容を表示する
    final state = ref.read(diaryCreateProvider);
    if (_isCompleted(state)) {
      _showGenerated(state);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  bool _isCompleted(DiaryCreateState state) {
    return !state.isLoading &&
        state.errorMessage == null &&
        state.generatedDiary.isNotEmpty;
  }

  void _showGenerated(DiaryCreateState state) {
    _titleController.text = state.generatedTitle;
    _contentController.text = state.generatedDiary;
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(diaryCreateProvider);

    // AIが書き終えたら、修正できるよう入力欄に反映する
    ref.listen(diaryCreateProvider, (previous, next) {
      if (previous?.isLoading == true && _isCompleted(next)) {
        _showGenerated(next);
      }
    });

    final isCompleted = _isCompleted(state);

    return Scaffold(
      appBar: AppBar(title: const Text("AI日記の確認")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: _buildBody(context, state),
      ),
      bottomNavigationBar: isCompleted
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                // 本文が空の日記は保存できない
                child: ValueListenableBuilder<TextEditingValue>(
                  valueListenable: _contentController,
                  builder: (context, value, child) {
                    return ElevatedButton.icon(
                      onPressed: value.text.trim().isEmpty ? null : _save,
                      icon: const Icon(Icons.save),
                      label: const Text("この内容で保存する"),
                    );
                  },
                ),
              ),
            )
          : null,
    );
  }

  Future<void> _save() async {
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    final saved = await ref.read(diaryCreateProvider.notifier).saveGeneratedDiary(
          title: _titleController.text,
          content: _contentController.text,
        );

    messenger.showSnackBar(
      SnackBar(
        content: Text(saved ? "日記を保存しました" : "保存に失敗しました"),
      ),
    );

    // 保存できたら、入力画面も閉じてホームに戻る
    if (saved) {
      navigator.popUntil((route) => route.isFirst);
    }
  }

  Widget _buildBody(BuildContext context, DiaryCreateState state) {
    if (state.isLoading) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text("日記を書いています…"),
          ],
        ),
      );
    }

    final errorMessage = state.errorMessage;
    if (errorMessage != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              errorMessage,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("入力画面に戻る"),
            ),
          ],
        ),
      );
    }

    return ListView(
      children: [
        Text(
          "AIが書いた内容です。必要なら修正してから保存してください。",
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _titleController,
          decoration: const InputDecoration(
            labelText: "タイトル",
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _contentController,
          decoration: const InputDecoration(
            labelText: "本文",
            border: OutlineInputBorder(),
            alignLabelWithHint: true,
          ),
          keyboardType: TextInputType.multiline,
          minLines: 10,
          maxLines: null,
        ),
      ],
    );
  }
}
