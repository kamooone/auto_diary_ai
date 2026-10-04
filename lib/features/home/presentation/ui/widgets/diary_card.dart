import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:auto_diary_ai/features/diary/domain/entities/diary.dart';
import 'package:auto_diary_ai/features/diary/presentation/ui/diary_detail_screen.dart';
import 'package:auto_diary_ai/features/diary_create/domain/entities/photo.dart';
import 'package:auto_diary_ai/features/diary_create/presentation/ui/widgets/photo_thumbnail.dart';

/// 日記アイテムをカードとして表示するウィジェット
class DiaryCard extends StatelessWidget {
  final Diary item;
  final int index;

  const DiaryCard({
    super.key,
    required this.item,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    final date = item.date;

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
              clipBehavior: Clip.antiAlias,
              child: ListTile(
                contentPadding: const EdgeInsets.all(12),
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: SizedBox(
                    width: 70,
                    height: 70,
                    // 写真を添えた日記は1枚目を表示する
                    child: item.photoIds.isEmpty
                        ? Container(
                            color: Colors.grey[200],
                            child: Icon(
                              Icons.menu_book,
                              color: Colors.grey[500],
                            ),
                          )
                        : PhotoThumbnail(
                            photo: Photo(
                              id: item.photoIds.first,
                              createdAt: item.date,
                            ),
                          ),
                  ),
                ),
                title: Text(
                  item.headline,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  "${date.year}/${date.month}/${date.day}"
                  "${item.isAiGenerated ? "・AI" : ""}",
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                ),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => DiaryDetailScreen(diary: item),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
