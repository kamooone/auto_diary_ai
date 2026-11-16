import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:auto_diary_ai/common/constants/app_colors.dart';
import 'package:auto_diary_ai/common/constants/app_sizes.dart';
import 'package:auto_diary_ai/features/diary/domain/entities/diary.dart';
import 'package:auto_diary_ai/features/diary/presentation/ui/diary_detail_screen.dart';
import 'package:auto_diary_ai/features/diary_create/domain/entities/photo.dart';
import 'package:auto_diary_ai/features/diary_create/presentation/ui/widgets/photo_thumbnail.dart';
import 'package:auto_diary_ai/features/home/domain/services/timeline_entries.dart';
import 'package:auto_diary_ai/common/widgets/timeline_row.dart';
import 'trail_illustration.dart';

/// ホーム画面の、日記の一覧(月ごとのページ。左に日付、縦の点線、右にカード)
class DiaryTimelineView extends StatelessWidget {
  const DiaryTimelineView({
    super.key,
    required this.months,
    required this.itemsPerMonth,
    required this.pageController,
    required this.onPageChanged,
  });

  /// 日記のある月(「2026-10」の形。新しい月が先頭)
  final List<String> months;
  final Map<String, List<Diary>> itemsPerMonth;
  final PageController pageController;
  final ValueChanged<int> onPageChanged;

  /// 日記が、この日数以下の月には、小さな絵と、はげましの一文を出す
  static const sparseDays = 3;

  @override
  Widget build(BuildContext context) {
    // 全体でいちばん新しい日記(オレンジの印にする)。日記のない月は、飛ばす
    Diary? latest;
    for (final month in months) {
      final items = itemsPerMonth[month];
      if (items != null && items.isNotEmpty) {
        latest = items.first;
        break;
      }
    }

    return PageView.builder(
      controller: pageController,
      // 新しい月が先頭(0番目)のため、向きを逆にして、
      // 右にスライドで翌月(新しい月)、左にスライドで先月(古い月)にする
      reverse: true,
      itemCount: months.length,
      onPageChanged: onPageChanged,
      itemBuilder: (context, pageIndex) {
        final month = months[pageIndex];
        final items = itemsPerMonth[month] ?? const <Diary>[];
        return _MonthPage(
          // 月を変えたときに、アニメーションをやり直す
          key: ValueKey(month),
          month: int.parse(month.split('-')[1]),
          items: items,
          latest: latest,
        );
      },
    );
  }
}

class _MonthPage extends StatelessWidget {
  const _MonthPage({
    super.key,
    required this.month,
    required this.items,
    required this.latest,
  });

  final int month;
  final List<Diary> items;
  final Diary? latest;

  @override
  Widget build(BuildContext context) {
    // その月に、日記がないときは、小さな絵と一文だけ
    if (items.isEmpty) {
      return ListView(
        padding: const EdgeInsets.only(bottom: 96),
        children: const [
          TrailIllustration(message: 'この月は、まだ日記がありません\n右下のボタンから日記を作成できます'),
        ],
      );
    }

    final entries = buildTimelineEntries(items, latest: latest);
    final sparse = countRecordedDays(items) <= DiaryTimelineView.sparseDays;

    return AnimationLimiter(
      child: ListView.builder(
        // 下は、右下のボタンに、最後の日記が隠れないように、広く空ける
        padding: const EdgeInsets.fromLTRB(
          AppSizes.space16,
          0,
          AppSizes.space16,
          96,
        ),
        itemCount: entries.length + 1 + (sparse ? 1 : 0),
        itemBuilder: (context, index) {
          if (index < entries.length) {
            return AnimationConfiguration.staggeredList(
              position: index,
              duration: const Duration(milliseconds: 400),
              child: SlideAnimation(
                verticalOffset: 40,
                child: FadeInAnimation(
                  child: TimelineRow(
                    date: entries[index].diary.date,
                    showDate: entries[index].showDate,
                    isLatest: entries[index].isLatest,
                    // 違う日の日記との間は広く、同じ日の日記どうしは、近くに置く
                    bottomGap:
                        index + 1 < entries.length &&
                            entries[index + 1].showDate
                        ? AppSizes.space24
                        : AppSizes.space12,
                    child: _DiaryCard(diary: entries[index].diary),
                  ),
                ),
              ),
            );
          }
          if (index == entries.length) return _Footer(month: month);
          return const TrailIllustration(message: '書いた日が、少しずつ\nあなたの軌跡になっていきます');
        },
      ),
    );
  }
}

class _DiaryCard extends StatelessWidget {
  const _DiaryCard({required this.diary});

  final Diary diary;

  @override
  Widget build(BuildContext context) {
    final hasPhoto = diary.photoIds.isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppSizes.radius16),
        boxShadow: AppColors.cardShadows,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppSizes.radius16),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => DiaryDetailScreen(diary: diary),
              ),
            );
          },
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 56),
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                AppSizes.space16,
                hasPhoto ? AppSizes.space12 : AppSizes.space8,
                AppSizes.space8,
                hasPhoto ? AppSizes.space12 : AppSizes.space8,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          diary.headline,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 15,
                            height: 1.35,
                            fontWeight: FontWeight.w400,
                            color: AppColors.text,
                          ),
                        ),
                        if (diary.isAiGenerated) ...[
                          const SizedBox(height: AppSizes.space4),
                          const _AiChip(),
                        ],
                      ],
                    ),
                  ),
                  if (hasPhoto) ...[
                    const SizedBox(width: AppSizes.space12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(AppSizes.radius12),
                      child: SizedBox(
                        width: 72,
                        height: 72,
                        child: PhotoThumbnail(
                          photo: Photo(
                            id: diary.photoIds.first,
                            createdAt: diary.date,
                          ),
                        ),
                      ),
                    ),
                  ],
                  const Icon(Icons.chevron_right, color: AppColors.chevron),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AiChip extends StatelessWidget {
  const _AiChip();

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('aiChip'),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.pink,
        borderRadius: BorderRadius.circular(AppSizes.radiusPill),
      ),
      child: const Text(
        'AI',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w400,
          color: AppColors.navyDark,
        ),
      ),
    );
  }
}

/// 一覧の終わりの、「10月のはじまり」
class _Footer extends StatelessWidget {
  const _Footer({required this.month});

  final int month;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 28,
      child: Row(
        children: [
          const SizedBox(width: kTimelineDateWidth),
          SizedBox(
            width: kTimelineLineWidth,
            child: CustomPaint(
              size: const Size(kTimelineLineWidth, 28),
              painter: _FooterPainter(),
            ),
          ),
          Text(
            '$month月のはじまり',
            style: const TextStyle(fontSize: 12, color: AppColors.textSub),
          ),
        ],
      ),
    );
  }
}

class _FooterPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final x = size.width / 2;
    final dash = Paint()
      ..color = AppColors.timelineDots
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    // 上から、終わりの点まで、続ける(前の行の線とつなぐ)
    for (var y = 0.0; y < 9; y += 7) {
      canvas.drawLine(Offset(x, y), Offset(x, y + 2), dash);
    }
    canvas.drawCircle(
      Offset(x, 14),
      4,
      Paint()..color = AppColors.timelineDots,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
