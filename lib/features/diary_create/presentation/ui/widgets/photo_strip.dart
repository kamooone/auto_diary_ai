import 'package:flutter/material.dart';

import '../../../domain/entities/photo.dart';
import 'photo_thumbnail.dart';

/// 写真のサムネイルを、横に並べる(タップで全画面表示などに使う)
class PhotoStrip extends StatelessWidget {
  const PhotoStrip({
    super.key,
    required this.photos,
    this.onTap,
    this.size = 64,
    this.radius = 6,
  });

  final List<Photo> photos;

  /// 写真をタップしたとき(何番目か)
  final ValueChanged<int>? onTap;

  /// 1枚の大きさ(正方形の一辺)と、角の丸み
  final double size;
  final double radius;

  @override
  Widget build(BuildContext context) {
    if (photos.isEmpty) return const SizedBox.shrink();
    return SizedBox(
      height: size,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: photos.length,
        separatorBuilder: (_, __) => const SizedBox(width: 6),
        itemBuilder: (context, i) => SizedBox(
          key: ValueKey(photos[i].id),
          width: size,
          child: GestureDetector(
            onTap: onTap == null ? null : () => onTap!(i),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(radius),
              child: PhotoThumbnail(photo: photos[i]),
            ),
          ),
        ),
      ),
    );
  }
}
