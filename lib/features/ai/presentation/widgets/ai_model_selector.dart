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

  // GeminiとGPTの違いを、並べて説明する
  void _showDifference(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) {
        final theme = Theme.of(context);

        Widget item(String title, String gemini, String gpt) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: theme.textTheme.titleSmall),
                const SizedBox(height: 2),
                Text("Gemini: $gemini", style: theme.textTheme.bodyMedium),
                Text("GPT: $gpt", style: theme.textTheme.bodyMedium),
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
                  item("提供元", "Google のAI", "OpenAI のAI"),
                  item(
                    "使用量(トークン)",
                    "標準の消費量です",
                    "Gemini より、多く消費する予定です",
                  ),
                  item(
                    "書き上がる文章",
                    "AIによって、文章の雰囲気や長さが少し変わります。"
                        "気に入らないときは、もう一方でも試してください",
                    "同上",
                  ),
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
        });
  }
}
