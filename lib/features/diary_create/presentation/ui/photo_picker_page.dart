import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../application/providers/diary_usecase_providers.dart';
import '../../domain/entities/photo.dart';
import '../../domain/services/photo_period_filter.dart';
import 'widgets/photo_period_filter_bar.dart';
import 'widgets/photo_thumbnail.dart';

/// 日記に使う写真を選択する画面
/// 「確定」で選択した写真の一覧を返す
class PhotoPickerPage extends ConsumerStatefulWidget {
  const PhotoPickerPage({
    super.key,
    required this.initialSelection,
    this.from,
    this.to,
  });

  final List<Photo> initialSelection;

  /// 初めに表示する写真の撮影期間([from]以上[to]未満)の目安(日記の日付や、AIに渡す情報の期間)
  /// 期間が1か月に収まるときはその月、ほかは始まりの年に絞って表示する。
  /// 画面の年と月の選択で、ほかの年月や、すべての写真に切り替えられる。
  /// 指定しない場合は、端末内のすべての写真を表示する
  final DateTime? from;
  final DateTime? to;

  @override
  ConsumerState<PhotoPickerPage> createState() => _PhotoPickerPageState();
}

class _PhotoPickerPageState extends ConsumerState<PhotoPickerPage> {
  static const _pageSize = 60;

  final _photos = <Photo>[];
  late final _selected = [...widget.initialSelection];

  // 年と月による絞り込み(初めは、日記の日付に合わせる)
  late var _filter = PhotoPeriodFilter.initial(from: widget.from, to: widget.to);

  // 年の選択肢(一番古い写真の年から、今年まで)
  late var _years = PhotoPeriodFilter.years(oldest: null, now: DateTime.now());

  // 絞り込みを変えたあとに、前の絞り込みの読み込み結果が届いても、使わないための番号
  var _generation = 0;

  int _page = 0;
  bool _isLoading = false;
  bool _hasMore = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadYears();
    _loadMore();
  }

  Future<void> _loadYears() async {
    try {
      final oldest = await ref.read(getPhotosUseCaseProvider).oldestDate();

      if (!mounted) return;
      setState(() {
        _years = PhotoPeriodFilter.years(oldest: oldest, now: DateTime.now());
      });
    } catch (e) {
      // 年の選択肢が今年だけになるだけなので、握りつぶす(写真の読み込みの失敗は、別に表示する)
      debugPrint(e.toString());
    }
  }

  // 年と月を変えて、写真を読み込み直す(選択済みの写真は、そのまま残す)
  void _changeFilter(PhotoPeriodFilter filter) {
    if (filter == _filter) return;

    setState(() {
      _filter = filter;
      _generation++;
      _photos.clear();
      _page = 0;
      _hasMore = true;
      _isLoading = false;
      _errorMessage = null;
    });

    _loadMore();
  }

  Future<void> _loadMore() async {
    if (_isLoading || !_hasMore) return;

    final generation = _generation;
    setState(() => _isLoading = true);

    try {
      final photos = await ref.read(getPhotosUseCaseProvider).execute(
        page: _page,
        size: _pageSize,
        from: _filter.from,
        to: _filter.to,
      );

      if (!mounted || generation != _generation) return;
      setState(() {
        _photos.addAll(photos);
        _page++;
        _hasMore = photos.length == _pageSize;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint(e.toString());

      if (!mounted || generation != _generation) return;
      setState(() {
        _errorMessage = "写真を読み込めませんでした。写真へのアクセスを許可してください。";
        _hasMore = false;
        _isLoading = false;
      });
    }
  }

  void _toggle(Photo photo) {
    final index = _selected.indexWhere((e) => e.id == photo.id);

    if (index >= 0) {
      setState(() => _selected.removeAt(index));
      return;
    }

    setState(() => _selected.add(photo));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("写真を選択 (${_selected.length}枚)"),
      ),
      body: Column(
        children: [
          PhotoPeriodFilterBar(
            years: _years,
            value: _filter,
            onChanged: _changeFilter,
          ),
          Expanded(child: _buildBody()),
        ],
      ),
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
            : Text(
                _filter == PhotoPeriodFilter.all
                    ? "写真がありません"
                    : "この期間に撮影した写真はありません",
              ),
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

  final Photo photo;
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
          PhotoThumbnail(photo: photo),
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
