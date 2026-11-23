import 'package:flutter/material.dart';

import '../../../../common/constants/app_sizes.dart';
import '../../../../common/widgets/app_search_field.dart';
import '../../../../common/widgets/filter_chip_field.dart';
import '../../domain/entities/x_archive_post_filter.dart';

/// 年・月・日のセレクトボックスと、検索の入力欄
class XArchiveFilterBar extends StatelessWidget {
  const XArchiveFilterBar({
    super.key,
    required this.years,
    required this.filter,
    required this.onChanged,
  });

  /// 選べる年(新しい年が先頭)
  final List<int> years;
  final XArchivePostFilter filter;
  final ValueChanged<XArchivePostFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    final year = filter.year;
    final month = filter.month;
    final days = year != null && month != null
        ? XArchivePostFilter.daysInMonth(year, month)
        : 0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSizes.space16,
        AppSizes.space4,
        AppSizes.space16,
        AppSizes.space8,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 幅が足りない画面(小さい端末、文字を大きくした端末)では、次の行に折り返す
          Wrap(
            spacing: AppSizes.space8,
            runSpacing: AppSizes.space8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              FilterChipField<int>(
                key: const Key('xYear'),
                label: '年',
                value: year,
                options: [(null, 'すべて'), for (final y in years) (y, '$y年')],
                onChanged: (v) => onChanged(filter.withYear(v)),
              ),
              FilterChipField<int>(
                key: Key('xMonth-$year'),
                label: '月',
                value: month,
                options: [
                  (null, 'すべて'),
                  for (var m = 1; m <= 12; m++) (m, '$m月'),
                ],
                // 年を選ぶまでは、月は選べない
                onChanged: year == null
                    ? null
                    : (v) => onChanged(filter.withMonth(v)),
              ),
              FilterChipField<int>(
                key: Key('xDay-$year-$month'),
                label: '日',
                value: filter.day,
                options: [
                  (null, 'すべて'),
                  for (var d = 1; d <= days; d++) (d, '$d日'),
                ],
                // 月を選ぶまでは、日は選べない
                onChanged: month == null
                    ? null
                    : (v) => onChanged(filter.withDay(v)),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.space12),
          AppSearchField(
            key: const Key('xSearch'),
            hintText: '投稿を検索',
            onChanged: (v) => onChanged(filter.withQuery(v)),
          ),
        ],
      ),
    );
  }
}
