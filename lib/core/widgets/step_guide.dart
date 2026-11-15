import 'package:flutter/material.dart';

/// 手順の案内の、1つ分
class GuideStep {
  const GuideStep({required this.title, required this.body, this.icon});

  final String title;
  final String body;

  /// 手順の中で、押すボタンの見た目を見せるアイコン
  final IconData? icon;
}

/// 手順を、番号をつけて縦に並べた案内の画面(スクロールできる)
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
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(intro, style: theme.textTheme.bodyLarge),
          const SizedBox(height: 16),
          for (var i = 0; i < steps.length; i++)
            _StepTile(number: i + 1, step: steps[i]),
          if (note != null)
            Text(note!, style: theme.textTheme.bodySmall),
        ],
      ),
    );
  }
}

class _StepTile extends StatelessWidget {
  const _StepTile({required this.number, required this.step});

  final int number;
  final GuideStep step;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: theme.colorScheme.primary,
            foregroundColor: theme.colorScheme.onPrimary,
            child: Text("$number", style: theme.textTheme.labelLarge),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(step.title, style: theme.textTheme.titleMedium),
                const SizedBox(height: 4),
                Text(step.body, style: theme.textTheme.bodyMedium),
                if (step.icon != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: theme.dividerColor),
                    ),
                    child: Icon(step.icon, size: 28),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
