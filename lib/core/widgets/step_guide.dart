import 'package:flutter/material.dart';

import '../../common/constants/app_colors.dart';
import '../../common/constants/app_sizes.dart';
import '../../common/widgets/app_card.dart';

/// 手順の案内の、1つ分
class GuideStep {
  const GuideStep({required this.title, required this.body, this.icon});

  final String title;
  final String body;

  /// 手順の中で、押すボタンの見た目を見せるアイコン
  final IconData? icon;
}

/// 手順を、番号をつけて縦に並べた案内の画面(スクロールできる)
///
/// はじめの説明と、手順(左に番号の丸と点線のタイムライン)を、それぞれカードに入れる
class StepGuidePage extends StatelessWidget {
  const StepGuidePage({
    super.key,
    required this.title,
    required this.intro,
    required this.steps,
    this.note,
  });

  final String title;

  /// 手順の前に出す、はじめの説明
  final String intro;
  final List<GuideStep> steps;

  /// 手順のあとに出す、補足
  final String? note;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSizes.space16,
          20,
          AppSizes.space16,
          AppSizes.space24,
        ),
        children: [
          AppCard(
            padding: const EdgeInsets.all(AppSizes.space16),
            child: Text(
              intro,
              style: const TextStyle(
                fontSize: 15,
                height: 1.8,
                color: AppColors.text,
              ),
            ),
          ),
          const SizedBox(height: AppSizes.space16),
          AppCard(
            padding: const EdgeInsets.fromLTRB(
              AppSizes.space16,
              20,
              AppSizes.space16,
              AppSizes.space12,
            ),
            child: Column(
              children: [
                for (var i = 0; i < steps.length; i++)
                  _StepTile(
                    number: i + 1,
                    step: steps[i],
                    isLast: i == steps.length - 1,
                  ),
              ],
            ),
          ),
          if (note != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSizes.space4,
                AppSizes.space16,
                AppSizes.space4,
                0,
              ),
              child: Text(
                note!,
                style: const TextStyle(fontSize: 12, color: AppColors.textSub),
              ),
            ),
        ],
      ),
    );
  }
}

class _StepTile extends StatelessWidget {
  const _StepTile({
    required this.number,
    required this.step,
    required this.isLast,
  });

  final int number;
  final GuideStep step;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 左の列: 番号の丸と、次の手順までの点線(最後の手順の下は線なし)
          SizedBox(
            width: 32,
            child: Column(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.navy,
                  ),
                  child: Text(
                    '$number',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.white,
                    ),
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: CustomPaint(
                      size: const Size(2, double.infinity),
                      painter: _DottedLinePainter(),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: AppSizes.space12),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 3),
                    child: Text(
                      step.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.text,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSizes.space4),
                  Text(
                    step.body,
                    style: const TextStyle(
                      fontSize: 14,
                      height: 1.8,
                      color: AppColors.textSub,
                    ),
                  ),
                  if (step.icon != null) ...[
                    const SizedBox(height: AppSizes.space8),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.line),
                      ),
                      child: Icon(step.icon, size: 28, color: AppColors.navy),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DottedLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.timelineDots
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;
    final x = size.width / 2;
    for (var y = 4.0; y < size.height - 4; y += 5) {
      canvas.drawLine(Offset(x, y), Offset(x, y + 2), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
