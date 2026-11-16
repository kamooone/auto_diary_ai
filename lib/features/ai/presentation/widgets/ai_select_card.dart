import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:auto_diary_ai/common/constants/app_colors.dart';
import 'package:auto_diary_ai/common/constants/app_sizes.dart';
import 'package:auto_diary_ai/common/widgets/app_card.dart';
import '../../../plan/domain/entities/usage_info.dart';
import '../../application/providers/ai_model_provider.dart';
import '../../domain/entities/ai_model.dart';
import 'ai_model_selector.dart';

/// 使うAIの選択と、今月のAIの使用量を、1枚にまとめたカード
///
/// [showModel]がfalseのとき(AIを使わない書き方)は、AIの選択を隠して、使用量だけを出す。
/// [modelKey]・[usageKey]は、チュートリアルで、それぞれの部分を明るくするための目印
class AiSelectCard extends ConsumerWidget {
  const AiSelectCard({
    super.key,
    required this.usage,
    this.showModel = true,
    this.modelKey,
    this.usageKey,
    this.usageExtra,
  });

  /// サーバーから取得できていない場合はnull
  final UsageInfo? usage;

  final bool showModel;
  final GlobalKey? modelKey;
  final GlobalKey? usageKey;

  /// 使用量の下に出すもの(上限に達したときの案内など)
  final Widget? usageExtra;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final model = ref.watch(aiModelProvider);

    return AppCard(
      padding: const EdgeInsets.all(AppSizes.space16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showModel) ...[
            KeyedSubtree(
              key: modelKey,
              child: _ModelPart(
                model: model,
                onSelected: (value) =>
                    ref.read(aiModelProvider.notifier).select(value),
              ),
            ),
            const SizedBox(height: AppSizes.space12),
            const Divider(height: 1, thickness: 1, color: AppColors.line),
            const SizedBox(height: AppSizes.space12),
          ],
          KeyedSubtree(
            key: usageKey,
            child: _UsagePart(usage: usage, extra: usageExtra),
          ),
        ],
      ),
    );
  }
}

class _ModelPart extends StatelessWidget {
  const _ModelPart({required this.model, required this.onSelected});

  final AiModel model;
  final ValueChanged<AiModel> onSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                '使うAI',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
              ),
            ),
            InkWell(
              onTap: () => showAiModelDifference(context),
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  '違いを見る',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.navy,
                  ),
                ),
              ),
            ),
          ],
        ),
        // 切り替え(外枠の中に、Gemini / GPT。選んでいるほうが、ネイビー)
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: AppColors.pageBackground,
            borderRadius: BorderRadius.circular(AppSizes.radiusPill),
            border: Border.all(color: AppColors.line),
          ),
          child: Row(
            children: [
              for (final value in AiModel.values)
                Expanded(
                  child: _ToggleItem(
                    label: value.label,
                    selected: value == model,
                    onTap: () => onSelected(value),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: AppSizes.space8),
        Text(
          model.description,
          style: const TextStyle(fontSize: 12, color: AppColors.textSub),
        ),
      ],
    );
  }
}

class _ToggleItem extends StatelessWidget {
  const _ToggleItem({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      inMutuallyExclusiveGroup: true,
      checked: selected,
      button: true,
      child: Material(
        color: selected ? AppColors.navy : Colors.transparent,
        shape: const StadiumBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: SizedBox(
            height: 40,
            child: Center(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: selected ? AppColors.white : AppColors.textSub,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _UsagePart extends StatelessWidget {
  const _UsagePart({required this.usage, required this.extra});

  final UsageInfo? usage;
  final Widget? extra;

  @override
  Widget build(BuildContext context) {
    final usage = this.usage;
    final error = Theme.of(context).colorScheme.error;

    if (usage == null) {
      return const Text(
        '今月の使用量を取得できていません',
        style: TextStyle(fontSize: 12, color: AppColors.textSub),
      );
    }

    final percent = (usage.ratio * 100).floor();
    final color = usage.isExceeded ? error : AppColors.navy;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                '今月のAIの使用量',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
              ),
            ),
            Text(
              '$percent%',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: usage.isExceeded ? error : AppColors.navyDark,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSizes.space8),
        LinearProgressIndicator(
          value: usage.ratio,
          minHeight: 8,
          borderRadius: BorderRadius.circular(AppSizes.radiusPill),
          backgroundColor: AppColors.pink,
          color: color,
        ),
        const SizedBox(height: AppSizes.space8),
        Text(
          [
            '${_number(usage.usedTokens)} / ${_number(usage.limitTokens)} トークン',
            if (usage.resetsAt != null) '${_date(usage.resetsAt!)}にリセット',
          ].join(' ・ '),
          style: const TextStyle(fontSize: 12, color: AppColors.textSub),
        ),
        if (usage.tokenBalance > 0)
          Text(
            'うち、アカウントのトークン ${_number(usage.tokenBalance)}',
            style: const TextStyle(fontSize: 12, color: AppColors.textSub),
          ),
        if (extra != null) ...[const SizedBox(height: AppSizes.space8), extra!],
      ],
    );
  }

  // 3桁ごとに、カンマで区切る
  static String _number(int value) {
    return value.toString().replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (_) => ',',
    );
  }

  static String _date(DateTime date) {
    final local = date.toLocal();
    return '${local.month}月${local.day}日';
  }
}
