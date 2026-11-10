import 'package:flutter/material.dart';

import '../../../domain/entities/photo.dart';
import 'photo_thumbnail.dart';

/// 写真のサムネイルを、横に並べる(タップで全画面表示などに使う)
class PhotoStrip extends StatelessWidget {
  const PhotoStrip({super.key, required this.photos, this.onTap});

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
