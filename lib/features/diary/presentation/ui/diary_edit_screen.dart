import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../diary_create/application/providers/diary_usecase_providers.dart';
import '../../../diary_create/domain/entities/photo.dart';
import '../../../diary_create/presentation/ui/widgets/photo_selection_card.dart';
import '../../application/providers/diary_providers.dart';
import '../../domain/entities/diary.dart';

/// 保存した日記のタイトル・本文・写真を編集する画面
class DiaryEditScreen extends ConsumerStatefulWidget {
  const DiaryEditScreen({super.key, required this.diary});

  final Diary diary;

  @override
  ConsumerState<DiaryEditScreen> createState() => _DiaryEditScreenState();
}

class _DiaryEditScreenState extends ConsumerState<DiaryEditScreen> {
  late final _titleController = TextEditingController(text: widget.diary.title);
  late final _contentController =
      TextEditingController(text: widget.diary.content);

  // 日記に添えた写真
  late List<Photo> _photos = [
    for (final id in widget.diary.photoIds)
      Photo(id: id, createdAt: widget.diary.date),
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final diary = widget.diary;

    try {
      // 日付や、AIが書いた日記かどうかは変えない
      await ref.read(saveDiaryUseCaseProvider).execute(
        Diary(
          id: diary.id,
          date: diary.date,
          title: _titleController.text.trim(),
          content: _contentController.text.trim(),
          isAiGenerated: diary.isAiGenerated,
          photoIds: [for (final photo in _photos) photo.id],
          createdAt: diary.createdAt,
        ),
      );
    } catch (e) {
      debugPrint(e.toString());

      messenger.showSnackBar(
        const SnackBar(content: Text("保存に失敗しました")),
      );
      return;
    }

    messenger.showSnackBar(
      const SnackBar(content: Text("日記を更新しました")),
    );
    navigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    final plan = ref.watch(diaryPlanProvider);
    final date = widget.diary.date;

    return Scaffold(
      appBar: AppBar(title: const Text("日記を編集")),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            "${date.year}年${date.month}月${date.day}日の日記",
            style: Theme.of(context).textTheme.titleMedium,
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
            minLines: 8,
            maxLines: null,
          ),
          const SizedBox(height: 12),

          // 写真は、撮影日に関係なく選び直せる
          PhotoSelectionCard(
            photos: _photos,
            maxPhotos: plan.maxPhotos,
            onChanged: (photos) {
              setState(() => _photos = photos);
            },
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          // 本文が空の日記は保存できない
          child: ValueListenableBuilder<TextEditingValue>(
            valueListenable: _contentController,
            builder: (context, value, child) {
              return ElevatedButton.icon(
                onPressed: value.text.trim().isEmpty ? null : _save,
                icon: const Icon(Icons.save),
                label: const Text("変更を保存する"),
              );
            },
          ),
        ),
      ),
    );
  }
}
