import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/providers/x_archive_providers.dart';
import '../../domain/entities/x_archive_post.dart';
import '../../domain/entities/x_archive_post_filter.dart';
import '../../../../common/constants/app_colors.dart';
import '../../../../common/constants/app_sizes.dart';
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
    final page = await ref
        .read(xArchiveRepositoryProvider)
        .findPage(offset: _posts.length, limit: _pageSize, filter: _filter);
    if (!mounted || generation != _generation) return;
    setState(() {
      _posts.addAll(page);
      _hasMore = page.length == _pageSize;
    });
    _loading = false;
  }

  void _onFilterChanged(XArchivePostFilter filter) {
    final queryOnly =
        filter.year == _filter.year &&
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
    // 写真・本文・日時を変えたり、削除したりしたかもしれないので、その1件を読み直す
    final updated = await ref
        .read(xArchiveRepositoryProvider)
        .find(post.tweetId);
    if (!mounted) return;
    if (updated == null || updated.createdAt != post.createdAt) {
      // 削除したときや、日時を変えたときは、件数・年・並びが変わるので、読み直す
      await _reload(refreshYears: true);
      return;
    }
    if (index >= _posts.length) return;
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
        title: const Text('取り込んだXの投稿一覧'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'delete') {
                _deleteAll();
              }
            },
            itemBuilder: (context) => const [
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
          // 件数(「21,854件」。数字だけ太字)
          Padding(
            padding: const EdgeInsets.fromLTRB(
              20,
              0,
              AppSizes.space16,
              AppSizes.space8,
            ),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text.rich(
                TextSpan(
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSub,
                  ),
                  children: [
                    TextSpan(
                      text: _withCommas(_matched),
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppColors.navyDark,
                      ),
                    ),
                    const TextSpan(text: '件'),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: empty
                ? Center(
                    child: Text(
                      _filter.isNone ? '取り込んだ投稿はありません' : '条件に合う投稿がありません',
                      style: const TextStyle(color: AppColors.textSub),
                    ),
                  )
                : Scrollbar(
                    controller: _scroll,
                    // つまんで、すばやく動かせるようにする
                    interactive: true,
                    thumbVisibility: true,
                    thickness: 8,
                    radius: const Radius.circular(4),
                    // 投稿は、1枚のカードのように見せる(読み込みは、今のまま、見えている分だけ作る)
                    child: ListView.builder(
                      controller: _scroll,
                      padding: const EdgeInsets.fromLTRB(
                        AppSizes.space16,
                        0,
                        AppSizes.space16,
                        AppSizes.space24,
                      ),
                      itemCount: _posts.length,
                      itemBuilder: (context, i) => _CardRow(
                        isFirst: i == 0,
                        isLast: i == _posts.length - 1 && !_hasMore,
                        child: XArchivePostTile(
                          key: ValueKey(_posts[i].tweetId),
                          post: _posts[i],
                          onTap: () => _openDetail(i),
                        ),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

// 3桁ごとに、カンマで区切る
String _withCommas(int value) {
  return value.toString().replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (_) => ',',
  );
}

/// 一覧の1行。つなげると、1枚の白いカードに見える(行の間に1pxの線)
class _CardRow extends StatelessWidget {
  const _CardRow({
    required this.isFirst,
    required this.isLast,
    required this.child,
  });

  final bool isFirst;
  final bool isLast;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.vertical(
      top: Radius.circular(isFirst ? AppSizes.radius16 : 0),
      bottom: Radius.circular(isLast ? AppSizes.radius16 : 0),
    );

    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: radius,
        border: isLast
            ? null
            : const Border(bottom: BorderSide(color: AppColors.line)),
      ),
      child: Material(
        type: MaterialType.transparency,
        borderRadius: radius,
        clipBehavior: Clip.antiAlias,
        child: child,
      ),
    );
  }
}
