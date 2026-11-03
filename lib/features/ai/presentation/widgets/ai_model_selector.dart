import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../application/providers/ai_model_provider.dart';
import '../../domain/entities/ai_model.dart';

/// 日記を書くAIの種類(Gemini / GPT)を選ぶ
class AiModelSelector extends ConsumerWidget {
  const AiModelSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final model = ref.watch(aiModelProvider);
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("使うAI", style: theme.textTheme.titleSmall),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: SegmentedButton<AiModel>(
            segments: [
              for (final value in AiModel.values)
                ButtonSegment(value: value, label: Text(value.label)),
            ],
            selected: {model},
            showSelectedIcon: false,
            onSelectionChanged: (selection) {
              ref.read(aiModelProvider.notifier).select(selection.first);
            },
          ),
        ),
        const SizedBox(height: 4),
        Text(model.description, style: theme.textTheme.bodySmall),
      ],
    );
  }
}
