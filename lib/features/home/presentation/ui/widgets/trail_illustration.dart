import 'package:flutter/material.dart';
import 'package:auto_diary_ai/common/constants/app_colors.dart';

/// 日記が少ないとき・まだないときに出す、点線がピンに向かう、小さな絵
class TrailIllustration extends StatelessWidget {
  const TrailIllustration({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 240,
            height: 130,
            child: CustomPaint(painter: _TrailPainter()),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              height: 1.7,
              color: AppColors.textSub,
            ),
          ),
        ],
      ),
    );
  }
}

class _TrailPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const start = Offset(24, 108);
    const middle = Offset(112, 74);
    const goal = Offset(196, 32);

    final dash = Paint()
      ..color = AppColors.timelineDots
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round;

    _dotted(canvas, start, middle, dash);
    _dotted(canvas, middle, goal + const Offset(-4, 14), dash);

    // 途中の、白い丸(ふちはネイビー)
    for (final point in [start, middle]) {
      canvas.drawCircle(point, 6, Paint()..color = AppColors.pageBackground);
      canvas.drawCircle(
        point,
        6,
        Paint()
          ..color = AppColors.navy
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.4,
      );
    }

    // ゴールの、オレンジのピン
    final pin = Path()
      ..moveTo(goal.dx, goal.dy + 24)
      ..lineTo(goal.dx - 13, goal.dy + 8)
      ..arcToPoint(
        Offset(goal.dx + 13, goal.dy + 8),
        radius: const Radius.circular(16),
        clockwise: true,
        largeArc: true,
      )
      ..close();
    canvas.drawPath(pin, Paint()..color = AppColors.orange);
    canvas.drawCircle(
      Offset(goal.dx, goal.dy - 2),
      5,
      Paint()..color = AppColors.white,
    );
  }

  void _dotted(Canvas canvas, Offset from, Offset to, Paint paint) {
    final distance = (to - from).distance;
    final direction = (to - from) / distance;
    for (var d = 12.0; d < distance - 8; d += 9) {
      canvas.drawCircle(from + direction * d, 1.4, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
