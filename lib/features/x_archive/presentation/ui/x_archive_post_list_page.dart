import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../../application/providers/x_archive_providers.dart';
import '../../domain/entities/x_archive_post.dart';
import '../../domain/entities/x_archive_post_filter.dart';
import 'x_archive_filter_bar.dart';
import 'x_archive_post_detail_page.dart';
import 'x_archive_post_tile.dart';

/// 取り込んだXの投稿を、新しい順に見る画面(年・月・日と検索語で絞り込める)
class XArchivePostListPage extends ConsumerStatefulWidget {
  const XArchivePostListPage({super.key});

  @override
  ConsumerState<XArchivePostListPage> createState() =>
      _XArchivePostListPageState();
}

class _XArchivePostListPageState extends ConsumerState<XArchivePostListPage> {
  static const _pageSize = 100;

  final _scroll = ScrollController();
  final _posts = <XArchivePost>[];
  List<int> _years = [];
  XArchivePostFilter _filter = XArchivePostFilter.none;
  int _matched = 0;
  bool _loading = false;
  bool _hasMore = true;

  // 条件を変えたら増やす。古い条件の読み込み結果を捨てるための番号
  int _generation = 0;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(() {
      if (_scroll.position.extentAfter < 600) _loadMore();
    });
    _reload(refreshYears: true);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _scroll.dispose();
    super.dispose();
  }

  /// 条件に合う投稿を、最初から読み直す
  Future<void> _reload({bool refreshYears = false}) async {
    final generation = ++_generation;
    final repo = ref.read(xArchiveRepositoryProvider);
    final filter = _filter;

    if (refreshYears) {
      final counts = await repo.countByYear();
      if (!mounted || generation != _generation) return;
      _years = counts.keys.toList()..sort((a, b) => b.compareTo(a));
      if (filter.year != null && !counts.containsKey(filter.year)) {
        _filter = XArchivePostFilter.none.withQuery(filter.query);
      }
    }

    final matched = await repo.countMatching(_filter);
    if (!mounted || generation != _generation) return;
    setState(() {
      _matched = matched;
      _posts.clear();
      _hasMore = true;
      _loading = false;
    });
    if (_scroll.hasClients) _scroll.jumpTo(0);
    await _loadMore();
  }

  Future<void> _loadMore() async {
    if (_loading || !_hasMore) return;
    _loading = true;
    final generation = _generation;
    final page = await ref.read(xArchiveRepositoryProvider).findPage(
          offset: _posts.length,
          limit: _pageSize,
          filter: _filter,
        );
    if (!mounted || generation != _generation) return;
    setState(() {
      _posts.addAll(page);
      _hasMore = page.length == _pageSize;
    });
    _loading = false;
  }

  void _onFilterChanged(XArchivePostFilter filter) {
    final queryOnly = filter.year == _filter.year &&
        filter.month == _filter.month &&
        filter.day == _filter.day;
    setState(() => _filter = filter);

    _debounce?.cancel();
    if (queryOnly) {
      // 文字を打つたびに探さないよう、少し待つ
      _debounce = Timer(const Duration(milliseconds: 300), _reload);
    } else {
      _reload();
    }
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
    await _reload(refreshYears: true);
  }

  @override
  Widget build(BuildContext context) {
    final empty = _posts.isEmpty && !_loading && !_hasMore;

    return Scaffold(
      appBar: AppBar(
        title: const Text('取り込んだXの投稿'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'import') {
                context
                    .push(AppRoutes.xArchiveImport)
                    .then((_) => _reload(refreshYears: true));
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
          XArchiveFilterBar(
            years: _years,
            filter: _filter,
            onChanged: _onFilterChanged,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '$_matched件',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ),
          Expanded(
            child: empty
                ? Center(
                    child: Text(
                      _filter.isNone ? '取り込んだ投稿はありません' : '条件に合う投稿がありません',
                    ),
                  )
                : Scrollbar(
                    controller: _scroll,
                    // つまんで、すばやく動かせるようにする
                    interactive: true,
                    thumbVisibility: true,
                    thickness: 8,
                    radius: const Radius.circular(4),
                    child: ListView.separated(
                      controller: _scroll,
                      itemCount: _posts.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, i) => XArchivePostTile(
                        key: ValueKey(_posts[i].tweetId),
                        post: _posts[i],
                        onTap: () => _openDetail(i),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
