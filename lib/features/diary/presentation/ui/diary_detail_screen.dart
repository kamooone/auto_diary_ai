import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../diary_create/domain/entities/photo.dart';
import '../../../diary_create/presentation/ui/widgets/photo_thumbnail.dart';
import '../../application/providers/diary_providers.dart';
import '../../domain/entities/diary.dart';

/// 保存した日記を表示する画面
class DiaryDetailScreen extends ConsumerWidget {
  const DiaryDetailScreen({super.key, required this.diary});

  final Diary diary;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final date = diary.date;

    return Scaffold(
      appBar: AppBar(
        title: Text("${date.year}年${date.month}月${date.day}日"),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: "削除",
            onPressed: () => _confirmDelete(context, ref),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (diary.title.trim().isNotEmpty) ...[
            Text(
              diary.title,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 4),
          ],
          Text(
            diary.isAiGenerated ? "AIが書いた日記" : "自分で書いた日記",
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 12),
          if (diary.photoIds.isNotEmpty) ...[
            SizedBox(
              height: 96,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: diary.photoIds.length,
                separatorBuilder: (context, index) => const SizedBox(width: 6),
                itemBuilder: (context, index) {
                  return SizedBox(
                    width: 96,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: PhotoThumbnail(
                        photo: Photo(
                          id: diary.photoIds[index],
                          createdAt: diary.date,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
          ],
          SelectableText(diary.content),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final id = diary.id;
    if (id == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("日記を削除しますか？"),
          content: const Text("削除した日記は元に戻せません。"),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text("キャンセル"),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text("削除"),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    await ref.read(deleteDiaryUseCaseProvider).execute(id);

    if (!context.mounted) return;
    Navigator.of(context).pop();
  }
}
