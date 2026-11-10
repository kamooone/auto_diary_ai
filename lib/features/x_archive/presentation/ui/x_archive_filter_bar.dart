import 'package:flutter/material.dart';

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
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                flex: 3,
                child: DropdownButtonFormField<int?>(
                  key: const Key('xYear'),
                  initialValue: year,
                  decoration: _decoration('年'),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('すべて')),
                    for (final y in years)
                      DropdownMenuItem(value: y, child: Text('$y年')),
                  ],
                  onChanged: (v) => onChanged(filter.withYear(v)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: DropdownButtonFormField<int?>(
                  key: Key('xMonth-$year'),
                  initialValue: month,
                  decoration: _decoration('月'),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('すべて')),
                    for (var m = 1; m <= 12; m++)
                      DropdownMenuItem(value: m, child: Text('$m月')),
                  ],
                  // 年を選ぶまでは、月は選べない
                  onChanged:
                      year == null ? null : (v) => onChanged(filter.withMonth(v)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: DropdownButtonFormField<int?>(
                  key: Key('xDay-$year-$month'),
                  initialValue: filter.day,
                  decoration: _decoration('日'),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('すべて')),
                    for (var d = 1; d <= days; d++)
                      DropdownMenuItem(value: d, child: Text('$d日')),
                  ],
                  // 月を選ぶまでは、日は選べない
                  onChanged:
                      month == null ? null : (v) => onChanged(filter.withDay(v)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            key: const Key('xSearch'),
            decoration: const InputDecoration(
              hintText: '投稿を検索(空白で区切ると、すべての語を含むもの)',
              prefixIcon: Icon(Icons.search),
              isDense: true,
              border: OutlineInputBorder(),
            ),
            onChanged: (v) => onChanged(filter.withQuery(v)),
          ),
        ],
      ),
    );
  }

  InputDecoration _decoration(String label) => InputDecoration(
        labelText: label,
        isDense: true,
        border: const OutlineInputBorder(),
      );
}
