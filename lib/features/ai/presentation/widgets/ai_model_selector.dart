import 'package:flutter/material.dart';
import '../../../privacy/presentation/ui/privacy_policy_page.dart';
import '../../domain/entities/ai_model.dart';

/// GeminiとGPTの、使うモデルの名前と特徴を、並べて説明する
void showAiModelDifference(BuildContext context) {
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
              const SizedBox(height: 4),
              Text(
                "書き上がる文章: ${model.writing}",
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 4),
              Text(
                "送った日記の扱い: ${model.dataNote}",
                style: theme.textTheme.bodyMedium,
              ),
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
              // タップすると、プライバシーポリシーの画面を開く
              InkWell(
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const PrivacyPolicyPage(),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Text(
                    "詳しくは、プライバシーポリシーをご確認ください。",
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.primary,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
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
