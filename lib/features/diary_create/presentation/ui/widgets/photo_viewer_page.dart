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
  // 最初に出す大きさ。速く出すため、画面に収まる程度にする
  static const _baseSide = 2048;
  static const _baseQuality = 90;

  // 拡大したときに読み直す大きさ。メモリとGPUの上限に収まる範囲にする
  static const _zoomedSide = 4096;
  static const _zoomedQuality = 95;

  // この倍率を超えて拡大したら、大きい画像に差し替える
  static const _zoomThreshold = 1.5;

  final _transform = TransformationController();

  late final Future<Uint8List?> _base = ref
      .read(photoRepositoryProvider)
      .getJpeg(widget.photo, maxSide: _baseSide, quality: _baseQuality);

  Uint8List? _zoomed;
  bool _zoomedRequested = false;

  @override
  void initState() {
    super.initState();
    _transform.addListener(_onTransform);
  }

  @override
  void dispose() {
    _transform.removeListener(_onTransform);
    _transform.dispose();
    super.dispose();
  }

  /// 元の写真が最初の大きさ以下なら、読み直しても変わらないので省く
  bool get _canBeSharper {
    final w = widget.photo.width;
    final h = widget.photo.height;
    if (w == null || h == null) return true;
    return (w > h ? w : h) > _baseSide;
  }

  void _onTransform() {
    if (_zoomedRequested || !_canBeSharper) return;
    if (_transform.value.getMaxScaleOnAxis() <= _zoomThreshold) return;
    _zoomedRequested = true;
    _loadZoomed();
  }

  Future<void> _loadZoomed() async {
    final bytes = await ref
        .read(photoRepositoryProvider)
        .getJpeg(widget.photo, maxSide: _zoomedSide, quality: _zoomedQuality);
    if (!mounted || bytes == null) return;
    setState(() => _zoomed = bytes);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Uint8List?>(
      future: _base,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        final bytes = _zoomed ?? snapshot.data;
        if (bytes == null) {
          return const Center(
            child: Text(
              '写真を読み込めませんでした',
              style: TextStyle(color: Colors.white70),
            ),
          );
        }
        return InteractiveViewer(
          transformationController: _transform,
          minScale: 1,
          maxScale: 5,
          child: Center(
            child: Image.memory(
              bytes,
              fit: BoxFit.contain,
              // 差し替えるときに、一瞬消えないようにする
              gaplessPlayback: true,
            ),
          ),
        );
      },
    );
  }
}
