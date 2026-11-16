import 'package:flutter/material.dart';
import 'package:auto_diary_ai/common/constants/app_colors.dart';

/// タイムラインの、日付の列の幅
const kTimelineDateWidth = 48.0;

/// タイムラインの、縦の点線の列の幅
const kTimelineLineWidth = 28.0;

/// 日付の数字の中心の高さ(丸い印を、ここにそろえる)
const _dotY = 17.0;

/// ホーム画面のタイムラインの、1行(左に日付、縦の点線と丸い印、右に[child])
///
/// 日記の一覧と、ひとことの一覧で、共通で使う。
/// [showDate]がfalseのとき(同じ日の2件目以降)は、日付と印を出さず、点線だけをつなぐ
class TimelineRow extends StatelessWidget {
  const TimelineRow({
    super.key,
    required this.date,
    required this.showDate,
    required this.bottomGap,
    required this.child,
    this.isLatest = false,
  });

  final DateTime date;
  final bool showDate;

  /// いちばん新しい記録か(オレンジの印)
  final bool isLatest;

  /// この行の下の空き(縦の点線は、この空きの間も、つながる)
  final double bottomGap;

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: kTimelineDateWidth,
            child: showDate ? _DateLabel(date: date) : null,
          ),
          SizedBox(
            width: kTimelineLineWidth,
            child: CustomPaint(
              painter: _LinePainter(showDot: showDate, isLatest: isLatest),
            ),
          ),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: bottomGap),
              child: child,
            ),
          ),
        ],
      ),
    );
  }
}

class _DateLabel extends StatelessWidget {
  const _DateLabel({required this.date});

  final DateTime date;

  static const _weekdays = ['月', '火', '水', '木', '金', '土', '日'];

  @override
  Widget build(BuildContext context) {
    final weekday = date.weekday;
    final color = weekday == DateTime.saturday
        ? AppColors.saturday
        : weekday == DateTime.sunday
        ? AppColors.sunday
        : AppColors.textSub;

    return Column(
      children: [
        Text(
          '${date.day}',
          style: const TextStyle(
            fontSize: 24,
            height: 1.1,
            fontWeight: FontWeight.w400,
            color: AppColors.navyDark,
          ),
        ),
        Text(
          _weekdays[weekday - 1],
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w400,
            color: color,
          ),
        ),
      ],
    );
  }
}

/// 縦の点線と、丸い印を描く
class _LinePainter extends CustomPainter {
  const _LinePainter({required this.showDot, required this.isLatest});

  final bool showDot;
  final bool isLatest;

  @override
  void paint(Canvas canvas, Size size) {
    final x = size.width / 2;

    // 点線(丸い印があるときは、印から下へ。同じ日の2件目以降は、上から下まで)
    final dash = Paint()
      ..color = AppColors.timelineDots
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    final top = showDot ? _dotY + 10 : 0.0;
    for (var y = top; y < size.height; y += 7) {
      canvas.drawLine(Offset(x, y), Offset(x, y + 2), dash);
    }

    if (!showDot) return;

    if (isLatest) {
      // いちばん新しい日記は、オレンジの塗りと、淡い輪
      canvas.drawCircle(
        Offset(x, _dotY),
        11,
        Paint()..color = AppColors.latestDotRing,
      );
      canvas.drawCircle(Offset(x, _dotY), 7, Paint()..color = AppColors.orange);
    } else {
      canvas.drawCircle(
        Offset(x, _dotY),
        6,
        Paint()..color = AppColors.pageBackground,
      );
      canvas.drawCircle(
        Offset(x, _dotY),
        6,
        Paint()
          ..color = AppColors.navy
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.2,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _LinePainter oldDelegate) =>
      oldDelegate.showDot != showDot || oldDelegate.isLatest != isLatest;
}
