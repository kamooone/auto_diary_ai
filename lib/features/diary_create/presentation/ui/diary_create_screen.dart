import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/diary_create_provider.dart';

class DiaryCreateScreen extends ConsumerWidget {
  const DiaryCreateScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(diaryCreateProvider);
    final viewModel = ref.read(diaryCreateProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text("AI日記作成")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              decoration: const InputDecoration(
                labelText: "タイトル",
                border: OutlineInputBorder(),
              ),
              onChanged: viewModel.setInputTitle,
            ),
            const SizedBox(height: 6),
            Expanded(
              child: TextField(
                decoration: const InputDecoration(
                  labelText: "本文",
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                keyboardType: TextInputType.multiline,
                maxLines: null,     // 無制限
                expands: true,      // 親の高さに合わせて伸縮
                textAlignVertical: TextAlignVertical.top,
                onChanged: viewModel.setMainContent,
              ),
            ),
            const SizedBox(height: 4),
            ElevatedButton.icon(
              onPressed: () async {
                await viewModel.pickPhoto();
              },
              icon: const Icon(Icons.add_a_photo),
              label: const Text("画像をアップロード"),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: state.isLoading ? null : () => viewModel.generateDiary(),
              child: state.isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text("AIに日記を書いてもらう"),
            ),
            const SizedBox(height: 16),
            if (state.generatedDiary.isNotEmpty)
              Expanded(
                child: SingleChildScrollView(
                  child: Card(
                    color: Colors.grey[100],
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(state.generatedDiary),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
