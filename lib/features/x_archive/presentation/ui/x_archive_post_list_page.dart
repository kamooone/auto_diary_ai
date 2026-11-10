import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../../application/providers/x_archive_providers.dart';
import '../../domain/entities/x_archive_post.dart';

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
                    itemBuilder: (context, i) => _PostTile(post: _posts[i]),
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

class _PostTile extends StatelessWidget {
  final XArchivePost post;

  const _PostTile({required this.post});

  static String _kindLabel(XArchivePost post) {
    switch (post.kind) {
      case XArchivePostKind.post:
        return '';
      case XArchivePostKind.reply:
        final to = post.replyToScreenName;
        return to == null ? 'リプライ' : '@$to へのリプライ';
      case XArchivePostKind.retweet:
        return 'リツイート';
      case XArchivePostKind.quote:
        return '引用';
    }
  }

  static String _date(DateTime utc) {
    final t = utc.add(const Duration(hours: 9));
    String two(int n) => n.toString().padLeft(2, '0');
    return '${t.year}/${two(t.month)}/${two(t.day)} ${two(t.hour)}:${two(t.minute)}';
  }

  @override
  Widget build(BuildContext context) {
    final kind = _kindLabel(post);
    final notes = [
      if (kind.isNotEmpty) kind,
      if (post.imageFileNames.isNotEmpty) '画像${post.imageFileNames.length}枚',
      if (post.hasVideo) '動画あり',
    ];

    return ListTile(
      title: Text(
        post.text.isEmpty ? '(本文なし)' : post.text,
        maxLines: 4,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        [_date(post.createdAt), ...notes].join('  ・  '),
      ),
    );
  }
}
