import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../common/constants/app_colors.dart';
import '../../../../common/constants/app_sizes.dart';
import '../../../../common/widgets/app_tag.dart';
import '../../../diary_create/application/providers/diary_usecase_providers.dart';
import '../../../diary_create/domain/entities/photo.dart';
import '../../../diary_create/presentation/ui/widgets/photo_strip.dart';
import '../../../diary_create/presentation/ui/widgets/photo_viewer_page.dart';
import '../../application/services/x_archive_photo_loader.dart';
import '../../domain/entities/x_archive_post.dart';
import 'x_archive_post_formatter.dart';

/// 取り込んだ投稿の1行(本文・日時・種類・結びつけた写真)
class XArchivePostTile extends ConsumerStatefulWidget {
  final XArchivePost post;
  final VoidCallback onTap;

  const XArchivePostTile({super.key, required this.post, required this.onTap});

  @override
  ConsumerState<XArchivePostTile> createState() => XArchivePostTileState();
}

class XArchivePostTileState extends ConsumerState<XArchivePostTile> {
  late Future<List<Photo>> _photos = _load();

  Future<List<Photo>> _load() {
    return loadXArchivePhotos(widget.post, ref.read(photoRepositoryProvider));
  }

  @override
  void didUpdateWidget(XArchivePostTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.post.tweetId != widget.post.tweetId ||
        oldWidget.post.photoIds != widget.post.photoIds) {
      _photos = _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final post = widget.post;
    final kind = XArchivePostFormatter.kindLabel(post);
    final replyTo = post.replyToScreenName;

    return InkWell(
      onTap: widget.onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.space16,
          vertical: 14,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              post.text.isEmpty ? '(本文なし)' : post.text,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 15,
                height: 1.7,
                color: AppColors.text,
              ),
            ),
            const SizedBox(height: AppSizes.space4),
            // 日時と、種類(リツイート・リプライなど)の札
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: AppSizes.space8,
              runSpacing: AppSizes.space4,
              children: [
                Text(
                  XArchivePostFormatter.date(post.createdAt),
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSub,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
                if (kind.isNotEmpty)
                  AppTag(post.kind == XArchivePostKind.reply ? 'リプライ' : kind),
                if (post.kind == XArchivePostKind.reply && replyTo != null)
                  Text(
                    '@$replyTo',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSub,
                    ),
                  ),
                if (post.kind != XArchivePostKind.retweet &&
                    post.imageFileNames.isNotEmpty)
                  AppTag('画像${post.imageFileNames.length}枚'),
                if (post.hasVideo) const AppTag('動画あり'),
              ],
            ),
            FutureBuilder<List<Photo>>(
              future: _photos,
              builder: (context, snapshot) {
                final photos = snapshot.data ?? const <Photo>[];
                if (photos.isEmpty) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(top: AppSizes.space8),
                  child: PhotoStrip(
                    photos: photos,
                    onTap: (i) =>
                        showPhotoViewer(context, photos, initialIndex: i),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
