import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:photo_manager/photo_manager.dart';
import '../../application/providers/diary_usecase_providers.dart';
import 'widgets/asset_thumbnail.dart';

/// 日記に使う写真を選択する画面
/// 「確定」で選択した写真の一覧を返す
class PhotoPickerPage extends ConsumerStatefulWidget {
  const PhotoPickerPage({
    super.key,
    required this.initialSelection,
    required this.maxSelection,
  });

  final List<AssetEntity> initialSelection;
  final int maxSelection;

  @override
  ConsumerState<PhotoPickerPage> createState() => _PhotoPickerPageState();
}

class _PhotoPickerPageState extends ConsumerState<PhotoPickerPage> {
  static const _pageSize = 60;

  final _photos = <AssetEntity>[];
  late final _selected = [...widget.initialSelection];

  int _page = 0;
  bool _isLoading = false;
  bool _hasMore = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadMore();
  }

  Future<void> _loadMore() async {
    if (_isLoading || !_hasMore) return;

    setState(() => _isLoading = true);

    try {
      final photos = await ref.read(getPhotosUseCaseProvider).execute(
        page: _page,
        size: _pageSize,
      );

      if (!mounted) return;
      setState(() {
        _photos.addAll(photos);
        _page++;
        _hasMore = photos.length == _pageSize;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint(e.toString());

      if (!mounted) return;
      setState(() {
        _errorMessage = "写真を読み込めませんでした。写真へのアクセスを許可してください。";
        _hasMore = false;
        _isLoading = false;
      });
    }
  }

  void _toggle(AssetEntity photo) {
    final index = _selected.indexWhere((e) => e.id == photo.id);

    if (index >= 0) {
      setState(() => _selected.removeAt(index));
      return;
    }

    if (_selected.length >= widget.maxSelection) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text("写真は最大${widget.maxSelection}枚まで選択できます")),
        );
      return;
    }

    setState(() => _selected.add(photo));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("写真を選択 (${_selected.length}/${widget.maxSelection})"),
      ),
      body: _buildBody(),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: ElevatedButton(
            onPressed: () => Navigator.of(context).pop(_selected),
            child: Text("確定（${_selected.length}枚）"),
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_errorMessage != null && _photos.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(_errorMessage!),
        ),
      );
    }

    if (_photos.isEmpty) {
      return Center(
        child: _isLoading
            ? const CircularProgressIndicator()
            : const Text("写真がありません"),
      );
    }

    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        // 末尾が近づいたら次のページを読み込む
        if (notification.metrics.extentAfter < 500) {
          _loadMore();
        }
        return false;
      },
      child: GridView.builder(
        padding: const EdgeInsets.all(2),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          mainAxisSpacing: 2,
          crossAxisSpacing: 2,
        ),
        itemCount: _photos.length,
        itemBuilder: (context, index) {
          final photo = _photos[index];
          final selectedIndex = _selected.indexWhere((e) => e.id == photo.id);

          return _PhotoTile(
            key: ValueKey(photo.id),
            photo: photo,
            selectedNumber: selectedIndex >= 0 ? selectedIndex + 1 : null,
            onTap: () => _toggle(photo),
          );
        },
      ),
    );
  }
}

class _PhotoTile extends StatelessWidget {
  const _PhotoTile({
    super.key,
    required this.photo,
    required this.selectedNumber,
    required this.onTap,
  });

  final AssetEntity photo;
  final int? selectedNumber;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isSelected = selectedNumber != null;

    return GestureDetector(
      onTap: onTap,
      child: Stack(
        fit: StackFit.expand,
        children: [
          AssetThumbnail(asset: photo),
          if (isSelected) Container(color: Colors.black38),
          Positioned(
            top: 4,
            right: 4,
            child: Container(
              width: 24,
              height: 24,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : Colors.black26,
                border: Border.all(color: Colors.white, width: 1.5),
              ),
              child: isSelected
                  ? Text(
                      "$selectedNumber",
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onPrimary,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  : null,
            ),
          ),
        ],
      ),
    );
  }
}
