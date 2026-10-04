import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/day_posts_provider.dart';
import 'widgets/day_posts_list.dart';

class DayPostsScreen extends ConsumerWidget {
  final DateTime date;

  const DayPostsScreen({
    super.key,
    required this.date,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final posts = ref.watch(dayPostsProvider(date));

    if (posts.isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${date.year}-${date.month}-${date.day}',
        ),
      ),
      body: DayPostsList(posts: posts.valueOrNull ?? []),
    );
  }
}
