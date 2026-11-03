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
        Row(
          children: [
            Expanded(child: Text("使うAI", style: theme.textTheme.titleSmall)),
            TextButton(
              onPressed: () => _showDifference(context),
              child: const Text("違いを見る"),
            ),
          ],
        ),
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

  // GeminiとGPTの、使うモデルの名前と特徴を、並べて説明する
  void _showDifference(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) {
        final theme = Theme.of(context);

        Widget item(AiModel model) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(model.label, style: theme.textTheme.titleSmall),
                const SizedBox(height: 2),
                Text(
                  "使うモデル: ${model.modelName}",
                  style: theme.textTheme.bodyMedium,
                ),
                Text(model.feature, style: theme.textTheme.bodyMedium),
              ],
            ),
          );
        }

        return AlertDialog(
          title: const Text("GeminiとGPTの違い"),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final model in AiModel.values) item(model),
                Text(
                  "送信した日記の扱いは、提供元ごとに規約が異なります。"
                  "詳しくは、プライバシーポリシーをご確認ください。",
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("閉じる"),
            ),
          ],
        );
      },
    );
  }
}
