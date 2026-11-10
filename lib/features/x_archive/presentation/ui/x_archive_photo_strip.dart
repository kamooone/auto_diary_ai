import 'package:flutter/material.dart';

import '../../../diary_create/domain/entities/photo.dart';
import '../../../diary_create/presentation/ui/widgets/photo_thumbnail.dart';

/// 投稿に結びつけた写真を、横に並べる
class XArchivePhotoStrip extends StatelessWidget {
  const XArchivePhotoStrip({super.key, required this.photos, this.onTap});

  final List<Photo> photos;

  /// 写真をタップしたとき(何番目か)
  final ValueChanged<int>? onTap;

  @override
  Widget build(BuildContext context) {
    if (photos.isEmpty) return const SizedBox.shrink();
    return SizedBox(
      height: 64,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: photos.length,
        separatorBuilder: (_, __) => const SizedBox(width: 6),
        itemBuilder: (context, i) => SizedBox(
          key: ValueKey(photos[i].id),
          width: 64,
          child: GestureDetector(
            onTap: onTap == null ? null : () => onTap!(i),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: PhotoThumbnail(photo: photos[i]),
            ),
          ),
        ),
      ),
    );
  }
}
