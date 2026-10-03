import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../application/providers/diary_usecase_providers.dart';
import '../../../domain/entities/photo.dart';

class PhotoThumbnail extends ConsumerStatefulWidget {
  const PhotoThumbnail({super.key, required this.photo});

  final Photo photo;

  @override
  ConsumerState<PhotoThumbnail> createState() => _PhotoThumbnailState();
}

class _PhotoThumbnailState extends ConsumerState<PhotoThumbnail> {
  late Future<Uint8List?> _thumbnail = _load();

  Future<Uint8List?> _load() {
    return ref.read(getPhotoThumbnailUseCaseProvider).execute(widget.photo);
  }

  @override
  void didUpdateWidget(PhotoThumbnail oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.photo.id != widget.photo.id) {
      _thumbnail = _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Uint8List?>(
      future: _thumbnail,
      builder: (context, snapshot) {
        final bytes = snapshot.data;
        if (bytes == null) {
          return Container(color: Colors.grey[300]);
        }
        return Image.memory(
          bytes,
          fit: BoxFit.cover,
          gaplessPlayback: true,
        );
      },
    );
  }
}
