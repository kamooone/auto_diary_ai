import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:auto_diary_ai/features/home/data/models/diary_item.dart';

/// 日記アイテムをカードとして表示するウィジェット
class DiaryCard extends StatelessWidget {
  final DiaryItem item;
  final int index;

  const DiaryCard({
    super.key,
    required this.item,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    return AnimationConfiguration.staggeredList(
      position: index,
      duration: const Duration(milliseconds: 500),
      child: SlideAnimation(
        verticalOffset: 50,
        child: FadeInAnimation(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Card(
              elevation: Theme.of(context).cardTheme.elevation,
              shape: Theme.of(context).cardTheme.shape,
              color: Theme.of(context).cardColor,
              child: ListTile(
                contentPadding: const EdgeInsets.all(12),
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: CachedNetworkImage(
                    imageUrl: item.thumbnailUrl,
                    width: 70,
                    height: 70,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => const SizedBox(
                      width: 70,
                      height: 70,
                      child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                    ),
                    errorWidget: (context, url, error) => const Icon(Icons.error, color: Colors.redAccent),
                  ),
                ),
                title: Text(
                  item.aiMemo,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  item.date,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
