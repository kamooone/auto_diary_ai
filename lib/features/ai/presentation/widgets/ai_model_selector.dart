import 'package:flutter/material.dart';
import 'package:auto_diary_ai/common/constants/app_colors.dart';
import 'package:auto_diary_ai/common/constants/app_sizes.dart';
import 'package:auto_diary_ai/common/widgets/app_bottom_sheet.dart';
import 'package:auto_diary_ai/common/widgets/app_buttons.dart';
import 'package:auto_diary_ai/common/widgets/app_card.dart';
import 'package:auto_diary_ai/common/widgets/app_tag.dart';
import '../../../privacy/presentation/ui/privacy_policy_page.dart';
import '../../domain/entities/ai_model.dart';

/// GeminiとGPTの、使うモデルの名前と特徴を、並べて説明する(下から出るシート)
void showAiModelDifference(BuildContext context) {
  showAppBottomSheet<void>(
    context,
    title: "GeminiとGPTの違い",
    builder: (context) => SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final model in AiModel.values) ...[
            _ModelCard(model: model),
            const SizedBox(height: AppSizes.space12),
          ],
          // タップすると、プライバシーポリシーの画面を開く
          InkWell(
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const PrivacyPolicyPage(),
              ),
            ),
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: AppSizes.space12),
              child: Text(
                "詳しくは、プライバシーポリシーをご確認ください",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.navy,
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSizes.space8),
          SecondaryButton(
            label: "閉じる",
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    ),
  );
}

class _ModelCard extends StatelessWidget {
  const _ModelCard({required this.model});

  final AiModel model;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(AppSizes.space16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  model.label,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: AppColors.text,
                  ),
                ),
              ),
              AppTag(model.modelName),
            ],
          ),
          _Item(title: "特徴", body: model.feature),
          _Item(title: "書き上がる文章", body: model.writing),
          _Item(title: "送った日記の扱い", body: model.dataNote),
        ],
      ),
    );
  }
}

class _Item extends StatelessWidget {
  const _Item({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSizes.space12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.textSub,
            ),
          ),
          Text(
            body,
            style: const TextStyle(
              fontSize: 14,
              height: 1.8,
              color: AppColors.text,
            ),
          ),
        ],
      ),
    );
  }
}
