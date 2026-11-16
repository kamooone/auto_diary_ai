import 'package:flutter/material.dart';
import 'package:auto_diary_ai/common/constants/app_colors.dart';
import 'package:auto_diary_ai/common/constants/app_sizes.dart';

/// 絞り込みの選択欄(年・月・日)。丸い白い札で、押すと、選択肢のメニューが開く
///
/// 中は「年」(項目名)+ 選んでいる値 + ⌄。[onChanged]が null のとき(年を選ぶ前の月・日など)は、
/// 押せず、値と⌄をうすい色にする。選択肢の値が null のものは、「すべて」などの解除に使える
class FilterChipField<T> extends StatelessWidget {
  const FilterChipField({
    super.key,
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  /// 項目名(「年」「月」「日」)
  final String label;

  /// 今、選んでいる値(null は、選択肢の中の、値が null のもの)
  final T? value;

  /// 選択肢(値と、表示する文字)
  final List<(T?, String)> options;

  /// 選んだとき。null なら、選べない
  final ValueChanged<T?>? onChanged;

  @override
  Widget build(BuildContext context) {
    final enabled = onChanged != null;
    final valueText = options
        .firstWhere((e) => e.$1 == value, orElse: () => options.first)
        .$2;

    return PopupMenuButton<_Choice<T>>(
      enabled: enabled,
      tooltip: label,
      position: PopupMenuPosition.under,
      color: AppColors.white,
      onSelected: (choice) => onChanged?.call(choice.value),
      itemBuilder: (context) => [
        for (final (v, text) in options)
          PopupMenuItem<_Choice<T>>(
            value: _Choice(v),
            child: Text(
              text,
              style: TextStyle(
                fontWeight: v == value ? FontWeight.w700 : FontWeight.w400,
              ),
            ),
          ),
      ],
      child: Container(
        height: 40,
        padding: const EdgeInsets.only(left: 14, right: AppSizes.space12),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(AppSizes.radiusPill),
          border: Border.all(color: AppColors.line),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 12, color: AppColors.textSub),
            ),
            const SizedBox(width: AppSizes.space8),
            Text(
              valueText,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: enabled ? AppColors.text : AppColors.disabledContent,
              ),
            ),
            const SizedBox(width: AppSizes.space4),
            Icon(
              Icons.keyboard_arrow_down,
              size: 16,
              color: enabled ? AppColors.navy : AppColors.radioOff,
            ),
          ],
        ),
      ),
    );
  }
}

// 値が null の選択肢も選べるように、包む(PopupMenuButton は、null を「選ばなかった」と扱うため)
class _Choice<T> {
  const _Choice(this.value);

  final T? value;
}
