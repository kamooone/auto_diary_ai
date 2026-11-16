import 'package:flutter/material.dart';
import 'package:auto_diary_ai/common/constants/app_colors.dart';
import 'package:auto_diary_ai/common/constants/app_sizes.dart';
import 'package:auto_diary_ai/features/diary/domain/entities/diary.dart';
import 'package:auto_diary_ai/features/diary_create/domain/entities/photo.dart';
import 'package:auto_diary_ai/features/diary_create/presentation/ui/widgets/photo_thumbnail.dart';

/// 曜日の色(列は、日曜が0、土曜が6)
Color calendarWeekdayColor(int column) {
  if (column == 0) return AppColors.sunday;
  if (column == 6) return AppColors.saturday;
  return AppColors.text;
}

/// カレンダーの、1日分のマス
///
/// 日記がある日は、白い面と影。ない日は、枠だけ。押せるのは、日記がある日だけ
class CalendarDayCell extends StatelessWidget {
  const CalendarDayCell({
    super.key,
    required this.day,
    required this.column,
    required this.diaries,
    required this.isLatest,
    required this.isToday,
    required this.onTap,
  });

  final DateTime day;

  /// 列(日曜が0、土曜が6)
  final int column;

  /// その日の日記(1件目のタイトルと写真を出す)
  final List<Diary> diaries;

  /// いちばん新しい記録の日か(オレンジの丸)
  final bool isLatest;

  final bool isToday;

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final hasDiary = diaries.isNotEmpty;
    final first = hasDiary ? diaries.first : null;
    final hasPhoto = first != null && first.photoIds.isNotEmpty;

    final content = Padding(
      padding: const EdgeInsets.all(AppSizes.space4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // 幅が足りない小さな画面では、日付の数字を、少し縮めて、「+1」と並べる
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: _DayNumber(
                    day: day.day,
                    column: column,
                    isLatest: isLatest,
                    isToday: isToday,
                  ),
                ),
              ),
              const Spacer(),
              // 同じ日に複数あるときは、2件目以降の数
              if (diaries.length > 1) MoreChip(count: diaries.length - 1),
            ],
          ),
          if (first != null) ...[
            const SizedBox(height: 3),
            Expanded(
              child: Align(
                alignment: Alignment.topLeft,
                child: Text(
                  first.headline,
                  maxLines: hasPhoto ? 2 : 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 10.5,
                    height: 1.4,
                    fontWeight: FontWeight.w500,
                    color: AppColors.navyDark,
                  ),
                ),
              ),
            ),
            if (hasPhoto)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  height: 30,
                  width: double.infinity,
                  child: PhotoThumbnail(
                    photo: Photo(
                      id: first.photoIds.first,
                      createdAt: first.date,
                    ),
                  ),
                ),
              ),
          ],
        ],
      ),
    );

    final radius = BorderRadius.circular(AppSizes.radius12);

    // 日記がない日は、背景なしで、枠だけ(押せない)
    if (!hasDiary) {
      return Container(
        decoration: BoxDecoration(
          borderRadius: radius,
          border: Border.all(color: AppColors.line),
        ),
        child: content,
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: radius,
        boxShadow: AppColors.cardShadows,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: radius,
        clipBehavior: Clip.antiAlias,
        child: InkWell(onTap: onTap, child: content),
      ),
    );
  }
}

class _DayNumber extends StatelessWidget {
  const _DayNumber({
    required this.day,
    required this.column,
    required this.isLatest,
    required this.isToday,
  });

  final int day;
  final int column;
  final bool isLatest;
  final bool isToday;

  static const _features = [FontFeature.tabularFigures()];

  @override
  Widget build(BuildContext context) {
    // いちばん新しい記録の日は、オレンジの丸に白い数字
    if (isLatest) {
      return Container(
        key: const Key('latestDay'),
        width: 22,
        height: 22,
        alignment: Alignment.center,
        decoration: const BoxDecoration(
          color: AppColors.orange,
          shape: BoxShape.circle,
        ),
        child: Text(
          '$day',
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: AppColors.white,
            fontFeatures: _features,
          ),
        ),
      );
    }

    // 今日(日記が、いちばん新しい日ではないとき)は、ネイビーの輪
    if (isToday) {
      return Container(
        key: const Key('todayDay'),
        width: 22,
        height: 22,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.navy, width: 1.5),
        ),
        child: Text(
          '$day',
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: AppColors.navy,
            fontFeatures: _features,
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(left: 3),
      child: Text(
        '$day',
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w800,
          color: calendarWeekdayColor(column),
          fontFeatures: _features,
        ),
      ),
    );
  }
}

/// 「+1」(同じ日の、ほかの日記の数)
class MoreChip extends StatelessWidget {
  const MoreChip({super.key, required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'ほかに$count件',
      excludeSemantics: true,
      child: Container(
        height: 16,
        padding: const EdgeInsets.symmetric(horizontal: 5),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.pink,
          borderRadius: BorderRadius.circular(AppSizes.radiusPill),
        ),
        child: Text(
          '+$count',
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w800,
            color: AppColors.navyDark,
          ),
        ),
      ),
    );
  }
}
