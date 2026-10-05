import 'package:flutter/material.dart';
import '../../../domain/entities/photo.dart';
import '../photo_picker_page.dart';
import 'photo_thumbnail.dart';

/// 日記に添える写真の選択と、選択済みの写真の一覧
class PhotoSelectionCard extends StatelessWidget {
  const PhotoSelectionCard({
    super.key,
    required this.photos,
    required this.maxPhotos,
    this.from,
    this.to,
    required this.onChanged,
  });

  /// 選択済みの写真
  final List<Photo> photos;

  final int maxPhotos;

  /// 選べる写真の撮影期間([from]以上[to]未満)
  /// 指定しない場合は、端末内のすべての写真から選べる
  final DateTime? from;
  final DateTime? to;

  final ValueChanged<List<Photo>> onChanged;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.photo_library),
            title: const Text("写真"),
            subtitle: Text("${photos.length}枚を選択中（最大$maxPhotos枚）"),
            trailing: const Icon(Icons.chevron_right),
            onTap: () async {
              final selected = await Navigator.of(context).push<List<Photo>>(
                MaterialPageRoute(
                  fullscreenDialog: true,
                  builder: (context) => PhotoPickerPage(
                    initialSelection: photos,
                    maxSelection: maxPhotos,
                    from: from,
                    to: to,
                  ),
                ),
              );

              if (selected != null) {
                onChanged(selected);
              }
            },
          ),
          if (photos.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: SizedBox(
                height: 72,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: photos.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(width: 6),
                  itemBuilder: (context, index) {
                    final photo = photos[index];

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
                              onTap: () => onChanged([
                                for (final other in photos)
                                  if (other.id != photo.id) other,
                              ]),
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
