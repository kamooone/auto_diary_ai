import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../diary_create/domain/services/day_grouper.dart';
import '../../../diary_create/domain/services/month_filter.dart';
import '../../../diary_create/presentation/ui/widgets/month_filter_bar.dart';
import '../../application/providers/share_providers.dart';
import '../../domain/entities/shared_post.dart';
import '../formatters/shared_post_format.dart';
import 'shared_post_edit_screen.dart';

/// 保存したXの投稿の一覧(設定画面から開く)
/// 投稿の削除、内容の修正、日時の変更ができる
class SharedPostListScreen extends ConsumerWidget {
  const SharedPostListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final posts = ref.watch(allSharedPostsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text("Xの投稿")),
      body: posts.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => const Center(child: Text("投稿を読み込めませんでした")),
        data: (posts) {
          if (posts.isEmpty) {
            return const Center(child: Text("保存したXの投稿はありません"));
          }

          return _PostList(posts: posts);
        },
      ),
    );
  }
}

class _PostList extends ConsumerStatefulWidget {
  const _PostList({required this.posts});

  final List<SharedPost> posts;

  @override
  ConsumerState<_PostList> createState() => _PostListState();
}

class _PostListState extends ConsumerState<_PostList> {
  // 年と月による絞り込み
  var _filter = MonthFilter.none;

  @override
  Widget build(BuildContext context) {
    // 削除などで、選んでいた月の投稿がなくなったときは、絞り込みを外す
    final times = widget.posts.map((e) => e.receivedAt).toList();
    final filter = times.any(_filter.matches) ? _filter : MonthFilter.none;
    final visible = widget.posts.where((e) => filter.matches(e.receivedAt));

    // 日付の新しい順に、見出しと投稿を1列に並べる
    final rows = <Object>[
      for (final day in groupByDay<SharedPost>(visible.toList(), (e) => e.receivedAt)
          .reversed) ...[
        day.date,
        ...day.items,
      ],
    ];

    return Column(
      children: [
        MonthFilterBar(
          times: times,
          value: filter,
          onChanged: (value) => setState(() => _filter = value),
        ),
        Expanded(child: _list(context, rows)),
      ],
    );
  }

  Widget _list(BuildContext context, List<Object> rows) {
    return ListView.builder(
      itemCount: rows.length,
      itemBuilder: (context, index) {
        final row = rows[index];

        if (row is DateTime) {
          return Container(
            width: double.infinity,
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              SharedPostFormat.date(row),
              style: Theme.of(context).textTheme.titleSmall,
            ),
          );
        }

        final post = row as SharedPost;

        return ListTile(
          leading: const Icon(Icons.share),
          title: Text(
            post.text.isEmpty ? "(テキストなし)" : post.text,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text(SharedPostFormat.time(post.receivedAt)),
          trailing: IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: "削除",
            onPressed: () => _confirmDelete(context, ref, post),
          ),
          onTap: () async {
            final changed = await Navigator.of(context).push<bool>(
              MaterialPageRoute(
                builder: (context) => SharedPostEditScreen(post: post),
              ),
            );

            if (changed == true) ref.invalidate(allSharedPostsProvider);
          },
        );
      },
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    SharedPost post,
  ) async {
    final messenger = ScaffoldMessenger.of(context);

    final confirmed = await confirmDeleteSharedPost(context, post);
    if (!confirmed) return;

    try {
      await ref.read(deleteSharedPostUseCaseProvider).execute(post);
      ref.invalidate(allSharedPostsProvider);
      messenger.showSnackBar(const SnackBar(content: Text("投稿を削除しました")));
    } catch (_) {
      messenger.showSnackBar(const SnackBar(content: Text("削除できませんでした")));
    }
  }
}

/// 投稿を削除してよいか確認する
Future<bool> confirmDeleteSharedPost(BuildContext context, SharedPost post) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text("この投稿を削除しますか？"),
      content: Text(
        post.text.isEmpty ? "(テキストなし)" : post.text,
        maxLines: 4,
        overflow: TextOverflow.ellipsis,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text("キャンセル"),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text("削除"),
        ),
      ],
    ),
  );

  return confirmed ?? false;
}
