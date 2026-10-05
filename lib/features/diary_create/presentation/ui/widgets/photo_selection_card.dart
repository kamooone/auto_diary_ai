import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../application/providers/diary_usecase_providers.dart';
import '../../../domain/entities/photo.dart';
import '../../providers/diary_create_provider.dart';
import '../photo_picker_page.dart';
import 'photo_thumbnail.dart';

/// 日記に添える写真の選択と、選択済みの写真の一覧
class PhotoSelectionCard extends ConsumerWidget {
  const PhotoSelectionCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(diaryCreateProvider);
    final viewModel = ref.read(diaryCreateProvider.notifier);
    final plan = ref.watch(diaryPlanProvider);

    return Card(
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.photo_library),
            title: const Text("写真"),
            subtitle: Text(
              "${state.selectedPhotos.length}枚を選択中（最大${plan.maxPhotos}枚）",
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () async {
              final photos = await Navigator.of(context).push<List<Photo>>(
                MaterialPageRoute(
                  fullscreenDialog: true,
                  builder: (context) => PhotoPickerPage(
                    initialSelection: state.selectedPhotos,
                    maxSelection: plan.maxPhotos,
                    from: state.startDate,
                    // 対象期間の最終日の終わりまで
                    to: DateTime(
                      state.endDate.year,
                      state.endDate.month,
                      state.endDate.day + 1,
                    ),
                  ),
                ),
              );

              if (photos != null) {
                viewModel.setSelectedPhotos(photos);
              }
            },
          ),
          if (state.selectedPhotos.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: SizedBox(
                height: 72,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: state.selectedPhotos.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(width: 6),
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
                              onTap: () => viewModel.removeSelectedPhoto(photo),
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
            ),
        ],
      ),
    );
  }
}
