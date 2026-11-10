import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../application/providers/diary_usecase_providers.dart';
import '../../../domain/entities/photo.dart';

/// 写真を全画面で見る画面(左右にめくれる。つまんで拡大できる)
Future<void> showPhotoViewer(
  BuildContext context,
  List<Photo> photos, {
  int initialIndex = 0,
}) {
  return Navigator.of(context).push(
    MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => PhotoViewerPage(photos: photos, initialIndex: initialIndex),
    ),
  );
}

class PhotoViewerPage extends StatefulWidget {
  const PhotoViewerPage({
    super.key,
    required this.photos,
    this.initialIndex = 0,
  });

  final List<Photo> photos;
  final int initialIndex;

  @override
  State<PhotoViewerPage> createState() => _PhotoViewerPageState();
}

class _PhotoViewerPageState extends State<PhotoViewerPage> {
  late final PageController _controller =
      PageController(initialPage: widget.initialIndex);
  late int _index = widget.initialIndex;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: widget.photos.length > 1
            ? Text('${_index + 1} / ${widget.photos.length}')
            : null,
      ),
      body: PageView.builder(
        controller: _controller,
        itemCount: widget.photos.length,
        onPageChanged: (i) => setState(() => _index = i),
        itemBuilder: (context, i) => _PhotoPage(photo: widget.photos[i]),
      ),
    );
  }
}

class _PhotoPage extends ConsumerStatefulWidget {
  const _PhotoPage({required this.photo});

  final Photo photo;

  @override
  ConsumerState<_PhotoPage> createState() => _PhotoPageState();
}

class _PhotoPageState extends ConsumerState<_PhotoPage> {
  // 画面いっぱいに見るので、サムネイルより大きく読む
  static const _maxSide = 2048;
  static const _quality = 90;

  late final Future<Uint8List?> _bytes = ref
      .read(photoRepositoryProvider)
      .getJpeg(widget.photo, maxSide: _maxSide, quality: _quality);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Uint8List?>(
      future: _bytes,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        final bytes = snapshot.data;
        if (bytes == null) {
          return const Center(
            child: Text(
              '写真を読み込めませんでした',
              style: TextStyle(color: Colors.white70),
            ),
          );
        }
        return InteractiveViewer(
          minScale: 1,
          maxScale: 5,
          child: Center(child: Image.memory(bytes, fit: BoxFit.contain)),
        );
      },
    );
  }
}
