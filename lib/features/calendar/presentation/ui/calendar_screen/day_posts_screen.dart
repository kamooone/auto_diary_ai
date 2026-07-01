import 'package:flutter/material.dart';
import 'package:isar/isar.dart';
import '../../../../share/data/models/shared_post_model.dart';
import 'widgets/day_posts_list.dart';

class DayPostsScreen extends StatelessWidget {
  final DateTime date;

  const DayPostsScreen({
    super.key,
    required this.date,
  });

  Future<List<SharedPostModel>> _fetchPosts() async {
    final isar = Isar.getInstance();

    if (isar == null) {
      throw Exception('Isar not initialized');
    }

    final start = DateTime(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1));

    return isar.sharedPostModels
        .filter()
        .receivedAtBetween(start, end)
        .findAll();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<SharedPostModel>>(
      future: _fetchPosts(),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
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