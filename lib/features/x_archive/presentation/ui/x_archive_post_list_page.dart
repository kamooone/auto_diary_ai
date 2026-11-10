import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../../application/providers/x_archive_providers.dart';
import '../../../diary_create/application/providers/diary_usecase_providers.dart';
import '../../../diary_create/domain/entities/photo.dart';
import '../../application/services/x_archive_photo_loader.dart';
import '../../domain/entities/x_archive_post.dart';
import 'x_archive_photo_strip.dart';
import 'x_archive_post_detail_page.dart';
import 'x_archive_post_formatter.dart';

/// 取り込んだXの投稿を、新しい順に見る画面(年で絞り込める)
class XArchivePostListPage extends ConsumerStatefulWidget {
  const XArchivePostListPage({super.key});

  @override
  ConsumerState<XArchivePostListPage> createState() =>
      _XArchivePostListPageState();
}

class _XArchivePostListPageState extends ConsumerState<XArchivePostListPage> {
  static const _pageSize = 50;

  final _scroll = ScrollController();
  final _posts = <XArchivePost>[];
  Map<int, int> _yearCounts = {};
  int? _year;
  bool _loading = false;
  bool _hasMore = true;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(() {
      if (_scroll.position.extentAfter < 400) _loadMore();
    });
    _reload();
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _reload() async {
    final repo = ref.read(xArchiveRepositoryProvider);
    final counts = await repo.countByYear();
    if (!mounted) return;
    setState(() {
      _yearCounts = counts;
      if (_year != null && !counts.containsKey(_year)) _year = null;
      _posts.clear();
      _hasMore = true;
    });
    await _loadMore();
  }

  Future<void> _loadMore() async {
    if (_loading || !_hasMore) return;
    _loading = true;
    final repo = ref.read(xArchiveRepositoryProvider);
    final page = await repo.findPage(
      offset: _posts.length,
      limit: _pageSize,
      year: _year,
    );
    if (!mounted) return;
    setState(() {
      _posts.addAll(page);
      _hasMore = page.length == _pageSize;
    });
    _loading = false;
  }

  Future<void> _openDetail(int index) async {
    final post = _posts[index];
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => XArchivePostDetailPage(post: post)),
    );
    if (!mounted) return;
    // 写真を変えたかもしれないので、その1件を読み直す
    final updated =
        await ref.read(xArchiveRepositoryProvider).find(post.tweetId);
    if (!mounted || updated == null || index >= _posts.length) return;
    setState(() => _posts[index] = updated);
  }

  Future<void> _deleteAll() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('取り込んだ投稿をすべて消しますか?'),
        content: const Text('アプリに取り込んだ分だけが消えます。Xの投稿やアーカイブのファイルは消えません。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('やめる'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('消す'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await ref.read(xArchiveRepositoryProvider).deleteAll();
    await _reload();
  }

  @override
  Widget build(BuildContext context) {
    final total = _yearCounts.values.fold<int>(0, (a, b) => a + b);
    final years = _yearCounts.keys.toList()..sort((a, b) => b.compareTo(a));

    return Scaffold(
      appBar: AppBar(
        title: const Text('取り込んだXの投稿'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'import') {
                context.push(AppRoutes.xArchiveImport).then((_) => _reload());
              } else if (value == 'delete') {
                _deleteAll();
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'import', child: Text('アーカイブを取り込む')),
              PopupMenuItem(value: 'delete', child: Text('すべて消す')),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          if (years.isNotEmpty)
            SizedBox(
              height: 52,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                children: [
                  _yearChip('すべて($total)', null),
                  for (final y in years) _yearChip('$y(${_yearCounts[y]})', y),
                ],
              ),
            ),
          Expanded(
            child: _posts.isEmpty && !_loading && !_hasMore
                ? const Center(child: Text('取り込んだ投稿はありません'))
                : ListView.separated(
                    controller: _scroll,
                    itemCount: _posts.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, i) => _PostTile(
                      key: ValueKey(_posts[i].tweetId),
                      post: _posts[i],
                      onTap: () => _openDetail(i),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _yearChip(String label, int? year) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: _year == year,
        onSelected: (_) {
          setState(() => _year = year);
          _reload();
        },
      ),
    );
  }
}

class _PostTile extends ConsumerStatefulWidget {
  final XArchivePost post;
  final VoidCallback onTap;

  const _PostTile({super.key, required this.post, required this.onTap});

  @override
  ConsumerState<_PostTile> createState() => _PostTileState();
}

class _PostTileState extends ConsumerState<_PostTile> {
  late Future<List<Photo>> _photos = _load();

  Future<List<Photo>> _load() {
    return loadXArchivePhotos(widget.post, ref.read(photoRepositoryProvider));
  }

  @override
  void didUpdateWidget(_PostTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.post.tweetId != widget.post.tweetId ||
        oldWidget.post.photoIds != widget.post.photoIds) {
      _photos = _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final post = widget.post;
    return ListTile(
      onTap: widget.onTap,
      title: Text(
        post.text.isEmpty ? '(本文なし)' : post.text,
        maxLines: 4,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            [
              XArchivePostFormatter.date(post.createdAt),
              ...XArchivePostFormatter.notes(post),
            ].join('  ・  '),
          ),
          FutureBuilder<List<Photo>>(
            future: _photos,
            builder: (context, snapshot) {
              final photos = snapshot.data ?? const <Photo>[];
              if (photos.isEmpty) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.only(top: 8),
                child: XArchivePhotoStrip(photos: photos),
              );
            },
          ),
        ],
      ),
    );
  }
}
