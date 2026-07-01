import 'package:flutter/material.dart';
import '../../../../../share/data/models/shared_post_model.dart';

class DayPostsList extends StatelessWidget {
  final List<SharedPostModel> posts;

  const DayPostsList({
    super.key,
    required this.posts,
  });

  @override
  Widget build(BuildContext context) {
    if (posts.isEmpty) {
      return const Center(
        child: Text('この日の投稿はありません'),
      );
    }

    return ListView.separated(
      itemCount: posts.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final post = posts[index];

        return ListTile(
          leading: const Icon(Icons.share),
          title: Text(
            post.text.isEmpty ? '(テキストなし)' : post.text,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text(post.receivedAt.toString()),
          onTap: () {
            showDialog(
              context: context,
              builder: (_) {
                return AlertDialog(
                  title: const Text('投稿詳細'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('URL'),
                      Text(post.url),
                      const SizedBox(height: 12),
                      const Text('テキスト'),
                      Text(post.text),
                      const SizedBox(height: 12),
                      const Text('日時'),
                      Text(post.receivedAt.toString()),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('閉じる'),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }
}