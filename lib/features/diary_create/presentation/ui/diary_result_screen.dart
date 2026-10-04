import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/diary_create_provider.dart';

/// AIが書いた日記を表示する画面
class DiaryResultScreen extends ConsumerWidget {
  const DiaryResultScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(diaryCreateProvider);

    final canSave = !state.isLoading &&
        state.errorMessage == null &&
        state.generatedDiary.isNotEmpty;

    return Scaffold(
      appBar: AppBar(title: const Text("AI日記")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: _buildBody(context, state.isLoading, state.errorMessage,
            state.generatedDiary),
      ),
      // 日記が書き上がったら保存できるようにする
      bottomNavigationBar: canSave
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: ElevatedButton.icon(
                  onPressed: () async {
                    final messenger = ScaffoldMessenger.of(context);
                    final navigator = Navigator.of(context);

                    final saved = await ref
                        .read(diaryCreateProvider.notifier)
                        .saveGeneratedDiary();

                    messenger.showSnackBar(
                      SnackBar(
                        content: Text(saved ? "日記を保存しました" : "保存に失敗しました"),
                      ),
                    );

                    // 保存できたら、入力画面も閉じてホームに戻る
                    if (saved) {
                      navigator.popUntil((route) => route.isFirst);
                    }
                  },
                  icon: const Icon(Icons.save),
                  label: const Text("この日記を保存する"),
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildBody(
    BuildContext context,
    bool isLoading,
    String? errorMessage,
    String diary,
  ) {
    if (isLoading) {
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

    return SingleChildScrollView(
      child: Card(
        color: Colors.grey[100],
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: SelectableText(diary),
        ),
      ),
    );
  }
}
