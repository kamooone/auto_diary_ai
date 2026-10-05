import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/app_info/install_date_provider.dart';
import '../../application/providers/diary_usecase_providers.dart';
import '../providers/diary_create_provider.dart';
import 'diary_ai_screen.dart';
import 'widgets/photo_selection_card.dart';

/// 日記を自分で書く画面
/// AIに書いてもらう場合は、ここからAI用の画面へ進む
class DiaryCreateScreen extends ConsumerWidget {
  const DiaryCreateScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(diaryCreateProvider);
    final viewModel = ref.read(diaryCreateProvider.notifier);
    final plan = ref.watch(diaryPlanProvider);

    final date = state.startDate;

    return Scaffold(
      appBar: AppBar(title: const Text("日記作成")),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ---------- いつの日記か
          Card(
            child: ListTile(
              leading: const Icon(Icons.calendar_today),
              title: const Text("日記の日付"),
              subtitle: Text("${date.year}年${date.month}月${date.day}日"),
              trailing: const Icon(Icons.chevron_right),
              onTap: () async {
                final now = DateTime.now();
                final installDate = ref.read(installDateProvider);

                // アプリを使い始めた日から今日までの1日を選ぶ
                final selected = await showDatePicker(
                  context: context,
                  initialDate: date,
                  firstDate: DateTime(
                    installDate.year,
                    installDate.month,
                    installDate.day,
                  ),
                  lastDate: DateTime(now.year, now.month, now.day),
                );

                if (selected != null) {
                  viewModel.setDate(selected);
                }
              },
            ),
          ),
          const SizedBox(height: 12),

          // ---------- 日記の内容
          TextField(
            decoration: const InputDecoration(
              labelText: "タイトル",
              border: OutlineInputBorder(),
            ),
            onChanged: viewModel.setInputTitle,
          ),
          const SizedBox(height: 8),
          TextField(
            decoration: const InputDecoration(
              labelText: "本文",
              border: OutlineInputBorder(),
              alignLabelWithHint: true,
            ),
            keyboardType: TextInputType.multiline,
            minLines: 8,
            maxLines: 16,
            onChanged: viewModel.setMainContent,
          ),
          const SizedBox(height: 12),

          // 自分で書く日記には、撮影日に関係なく写真を添えられる
          PhotoSelectionCard(
            photos: state.selectedPhotos,
            maxPhotos: plan.maxPhotos,
            onChanged: viewModel.setSelectedPhotos,
          ),
          const SizedBox(height: 16),

          // ---------- 保存
          ElevatedButton.icon(
            // 本文が空の日記は保存できない
            onPressed: state.content.trim().isEmpty
                ? null
                : () async {
                    final messenger = ScaffoldMessenger.of(context);
                    final navigator = Navigator.of(context);

                    final saved = await viewModel.saveManualDiary();

                    messenger.showSnackBar(
                      SnackBar(
                        content: Text(saved ? "日記を保存しました" : "保存に失敗しました"),
                      ),
                    );

                    if (saved) {
                      navigator.pop();
                    }
                  },
            icon: const Icon(Icons.save),
            label: const Text("保存する"),
          ),
          const SizedBox(height: 8),

          // ---------- AIに書いてもらう場合は専用の画面へ
          OutlinedButton.icon(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const DiaryAiScreen(),
                ),
              );
            },
            icon: const Icon(Icons.auto_awesome),
            label: const Text("AIに書いてもらう"),
          ),
        ],
      ),
    );
  }
}
