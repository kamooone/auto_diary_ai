import 'package:flutter/material.dart';
import '../../../ads/presentation/ad_top_layout.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../common/constants/app_colors.dart';
import '../../../../common/constants/app_sizes.dart';
import '../../../../common/widgets/app_card.dart';
import '../../application/providers/x_archive_providers.dart';
import '../../application/providers/x_archive_recall_providers.dart';
import '../../domain/entities/x_archive_post.dart';
import '../../domain/entities/x_archive_recall.dart';
import 'x_archive_post_detail_page.dart';
import 'x_archive_post_tile.dart';

/// 「過去のツイート紹介」(N年前の今日のツイートと、ランダムなツイート)
class XArchiveRecallPage extends ConsumerWidget {
  const XArchiveRecallPage({super.key, this.date});

  /// 紹介する日。渡さなければ、日本時間の今日
  final DateTime? date;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recall = ref.watch(xArchiveRecallProvider(date));

    return Scaffold(
      appBar: AppBar(title: const Text('過去のポスト(ツイート)')),
      body: AdTopLayout(
        child: recall.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => const Center(child: Text('読み込めませんでした')),
          data: (recall) {
            if (recall.isEmpty) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text(
                    '紹介できるポスト(ツイート)がありません\n設定の「Xのアーカイブを取り込む」から、取り込んでください',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.textSub),
                  ),
                ),
              );
            }

            return ListView(
              padding: const EdgeInsets.fromLTRB(
                AppSizes.space16,
                20,
                AppSizes.space16,
                AppSizes.space24,
              ),
              children: [
                // N年前の今日(丸から点線を伸ばして、その年の投稿をぶら下げる)
                for (final year in recall.years)
                  _YearBlock(
                    year: year,
                    onOpen: (post) => _open(context, ref, post),
                  ),
                if (recall.years.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(AppSizes.space8),
                    child: Text(
                      'この日と同じ月日のポスト(ツイート)は、見つかりませんでした',
                      style: TextStyle(fontSize: 14, color: AppColors.textSub),
                    ),
                  ),
                if (recall.randoms.isNotEmpty) ...[
                  const SizedBox(height: AppSizes.space24),
                  const _RandomHeading(),
                  const SizedBox(height: AppSizes.space12),
                  for (final post in recall.randoms)
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSizes.space12),
                      child: AppCard(
                        child: XArchivePostTile(
                          key: ValueKey(post.tweetId),
                          post: post,
                          style: XArchiveTileStyle.cardWithDate,
                          onTap: () => _open(context, ref, post),
                        ),
                      ),
                    ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }

  Future<void> _open(
    BuildContext context,
    WidgetRef ref,
    XArchivePost post,
  ) async {
    // 保存後に写真が変わっているかもしれないので、最新の内容で開く
    final latest = await ref
        .read(xArchiveRepositoryProvider)
        .find(post.tweetId);
    if (!context.mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => XArchivePostDetailPage(post: latest ?? post),
      ),
    );
  }
}

/// 「N年前の今日」の1年分(左に紺の丸と点線、右に見出しと、その年の投稿のカード)
class _YearBlock extends StatelessWidget {
  const _YearBlock({required this.year, required this.onOpen});

  final XArchiveRecallYear year;
  final ValueChanged<XArchivePost> onOpen;

  static const _weekdays = ['月', '火', '水', '木', '金', '土', '日'];

  @override
  Widget build(BuildContext context) {
    final d = year.date;
    final dateText =
        '${d.year}年${d.month}月${d.day}日（${_weekdays[d.weekday - 1]}）';

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSizes.space24),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              width: 40,
              child: Column(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.navy,
                    ),
                    child: Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: '${year.yearsAgo}',
                            style: const TextStyle(fontSize: 16),
                          ),
                          const TextSpan(
                            text: '年',
                            style: TextStyle(fontSize: 10),
                          ),
                        ],
                      ),
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppColors.white,
                      ),
                    ),
                  ),
                  Expanded(
                    child: CustomPaint(
                      size: const Size(2, double.infinity),
                      painter: _DotsPainter(),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSizes.space12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${year.yearsAgo}年前の今日',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.text,
                    ),
                  ),
                  Text(
                    dateText,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSub,
                    ),
                  ),
                  const SizedBox(height: AppSizes.space12),
                  for (final post in year.posts)
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSizes.space12),
                      child: AppCard(
                        child: XArchivePostTile(
                          key: ValueKey(post.tweetId),
                          post: post,
                          style: XArchiveTileStyle.card,
                          onTap: () => onOpen(post),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DotsPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.timelineDots
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;
    for (var y = 6.0; y < size.height - 4; y += 5) {
      canvas.drawLine(
        Offset(size.width / 2, y),
        Offset(size.width / 2, y + 2),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 「ほかにも、こんなポストが」の見出し(オレンジのきらきらと、小さな説明)
class _RandomHeading extends StatelessWidget {
  const _RandomHeading();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.pink,
          ),
          child: const Icon(
            Icons.auto_awesome,
            size: 20,
            color: AppColors.orange,
          ),
        ),
        const SizedBox(width: AppSizes.space12),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'ほかにも、こんなポストが',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.text,
                ),
              ),
              Text(
                '過去のポストから、ランダムに選んでいます',
                style: TextStyle(fontSize: 13, color: AppColors.textSub),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
