import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/photo.dart';
import '../../domain/usecases/generate_diary_usecase.dart';
import '../providers/diary_create_provider.dart';
import 'photo_picker_page.dart';
import 'widgets/photo_thumbnail.dart';

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
            if (state.selectedPhotos.isNotEmpty) ...[
              SizedBox(
                height: 72,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: state.selectedPhotos.length,
                  separatorBuilder: (context, index) => const SizedBox(width: 6),
                  itemBuilder: (context, index) {
                    final photo = state.selectedPhotos[index];

                    return SizedBox(
                      key: ValueKey(photo.id),
                      width: 72,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: PhotoThumbnail(photo: photo),
                          ),
                          Positioned(
                            top: 2,
                            right: 2,
                            child: GestureDetector(
                              onTap: state.isLoading
                                  ? null
                                  : () => viewModel.removeSelectedPhoto(photo),
                              child: const CircleAvatar(
                                radius: 10,
                                backgroundColor: Colors.black54,
                                child: Icon(
                                  Icons.close,
                                  size: 14,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 4),
            ],
            ElevatedButton.icon(
              onPressed: state.isLoading
                  ? null
                  : () async {
                      final photos =
                          await Navigator.of(context).push<List<Photo>>(
                        MaterialPageRoute(
                          fullscreenDialog: true,
                          builder: (context) => PhotoPickerPage(
                            initialSelection: state.selectedPhotos,
                            maxSelection: GenerateDiaryUseCase.maxPhotos,
                          ),
                        ),
                      );

                      if (photos != null) {
                        viewModel.setSelectedPhotos(photos);
                      }
                    },
              icon: const Icon(Icons.add_a_photo),
              label: Text(
                state.selectedPhotos.isEmpty
                    ? "写真を選択"
                    : "写真を選択（${state.selectedPhotos.length}枚）",
              ),
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
