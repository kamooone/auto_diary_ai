import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/providers/x_archive_providers.dart';
import '../../application/providers/x_archive_recall_providers.dart';
import '../../domain/entities/x_archive_post.dart';
import '../../domain/entities/x_archive_recall.dart';
import 'x_archive_post_detail_page.dart';
import 'x_archive_post_tile.dart';

/// 今日の「過去のツイート紹介」(N年前の今日のツイートと、ランダムなツイート)
class XArchiveRecallPage extends ConsumerWidget {
  const XArchiveRecallPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recall = ref.watch(xArchiveRecallProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('過去のツイート')),
      body: recall.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(child: Text('読み込めませんでした')),
        data: (recall) {
          if (recall.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  '紹介できるツイートがありません\n設定の「取り込んだXの投稿」から、Xのアーカイブを取り込んでください',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final rows = <Object>[
            for (final year in recall.years) ...[year, ...year.posts],
            if (recall.randoms.isNotEmpty) ...[
              'ほかのツイート',
              ...recall.randoms,
            ],
          ];

          return ListView.builder(
            itemCount: rows.length,
            itemBuilder: (context, i) {
              final row = rows[i];
              if (row is XArchivePost) {
                return XArchivePostTile(
                  key: ValueKey(row.tweetId),
                  post: row,
                  onTap: () => _open(context, ref, row),
                );
              }
              final String label;
              if (row is XArchiveRecallYear) {
                label = '${row.yearsAgo}年前の今日'
                    '(${row.date.year}年${row.date.month}月${row.date.day}日)';
              } else {
                label = row as String;
              }
              return Container(
                width: double.infinity,
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _open(
    BuildContext context,
    WidgetRef ref,
    XArchivePost post,
  ) async {
    // 保存後に写真が変わっているかもしれないので、最新の内容で開く
    final latest = await ref.read(xArchiveRepositoryProvider).find(post.tweetId);
    if (!context.mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => XArchivePostDetailPage(post: latest ?? post),
      ),
    );
  }
}
