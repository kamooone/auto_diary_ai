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

/// 投稿の見せ方
enum XArchiveTileStyle {
  /// 一覧用: 本文 → 日時と札 → 写真(小さめ)
  list,

  /// カード用: 本文 → 写真(88) → 日時と札(行間を広めに)
  card,

  /// ランダムな投稿用のカード: 日付(太字) → 本文 → 写真 → 時刻と札
  cardWithDate,
}

/// 取り込んだ投稿の1行(本文・日時・種類・結びつけた写真)
class XArchivePostTile extends ConsumerStatefulWidget {
  final XArchivePost post;
  final VoidCallback onTap;
  final XArchiveTileStyle style;

  const XArchivePostTile({
    super.key,
    required this.post,
    required this.onTap,
    this.style = XArchiveTileStyle.list,
  });

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
    final style = widget.style;
    final isCard = style != XArchiveTileStyle.list;
    final kind = XArchivePostFormatter.kindLabel(post);
    final replyTo = post.replyToScreenName;

    final photos = FutureBuilder<List<Photo>>(
      future: _photos,
      builder: (context, snapshot) {
        final photos = snapshot.data ?? const <Photo>[];
        if (photos.isEmpty) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.only(top: AppSizes.space8),
          child: PhotoStrip(
            photos: photos,
            size: isCard ? 88 : 64,
            radius: isCard ? AppSizes.radius12 : 6,
            onTap: (i) => showPhotoViewer(context, photos, initialIndex: i),
          ),
        );
      },
    );

    // 日時(または時刻)と、種類(リツイート・リプライなど)の札
    final meta = Padding(
      padding: EdgeInsets.only(
        top: isCard ? AppSizes.space12 : AppSizes.space4,
      ),
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: AppSizes.space8,
        runSpacing: AppSizes.space4,
        children: [
          Text(
            style == XArchiveTileStyle.cardWithDate
                ? XArchivePostFormatter.time(post.createdAt)
                : XArchivePostFormatter.date(post.createdAt),
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
              style: const TextStyle(fontSize: 12, color: AppColors.textSub),
            ),
          if (post.kind != XArchivePostKind.retweet &&
              post.imageFileNames.isNotEmpty)
            AppTag('画像${post.imageFileNames.length}枚'),
          if (post.hasVideo) const AppTag('動画あり'),
        ],
      ),
    );

    return InkWell(
      onTap: widget.onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: AppSizes.space16,
          vertical: isCard ? AppSizes.space16 : 14,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (style == XArchiveTileStyle.cardWithDate)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSizes.space8),
                child: Text(
                  XArchivePostFormatter.dateWithWeekday(post.createdAt),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.navyDark,
                  ),
                ),
              ),
            Text(
              post.text.isEmpty ? '(本文なし)' : post.text,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 15,
                height: isCard ? 1.8 : 1.7,
                color: AppColors.text,
              ),
            ),
            if (isCard) ...[photos, meta] else ...[meta, photos],
          ],
        ),
      ),
    );
  }
}
