import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/diary_create_provider.dart';

/// AIが書いた日記を表示する画面
class DiaryResultScreen extends ConsumerWidget {
  const DiaryResultScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(diaryCreateProvider);

    return Scaffold(
      appBar: AppBar(title: const Text("AI日記")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: _buildBody(context, state.isLoading, state.errorMessage,
            state.generatedDiary),
      ),
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
