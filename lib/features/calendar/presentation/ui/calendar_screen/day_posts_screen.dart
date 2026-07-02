import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../share/application/providers/share_service_provider.dart';
import '../../../../share/domain/entities/shared_post.dart';
import 'widgets/day_posts_list.dart';

class DayPostsScreen extends ConsumerWidget {
  final DateTime date;

  const DayPostsScreen({
    super.key,
    required this.date,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shareService = ref.read(shareServiceProvider);

    return FutureBuilder<List<SharedPost>>(
      future: shareService.getPosts(date),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        final posts = snapshot.data ?? [];

        return Scaffold(
          appBar: AppBar(
            title: Text(
              '${date.year}-${date.month}-${date.day}',
            ),
          ),
          body: DayPostsList(posts: posts),
        );
      },
    );
  }
}