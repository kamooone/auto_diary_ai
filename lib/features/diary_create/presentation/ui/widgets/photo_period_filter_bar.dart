import 'package:flutter/material.dart';
import '../../../domain/services/photo_period_filter.dart';

/// 写真を選ぶ画面の、年と月のセレクトボックス
class PhotoPeriodFilterBar extends StatelessWidget {
  const PhotoPeriodFilterBar({
    super.key,
    required this.years,
    required this.value,
    required this.onChanged,
  });

  /// 選べる年(新しい年が先頭)
  final List<int> years;
  final PhotoPeriodFilter value;
  final ValueChanged<PhotoPeriodFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    // 選択中の年が、選択肢にないとき(日記の日付が、一番古い写真より前など)も、選べるようにする
    final yearItems = {
      ...years,
      if (value.year != null) value.year!,
    }.toList()..sort((a, b) => b.compareTo(a));

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Row(
        children: [
          Expanded(
            child: DropdownButtonFormField<int?>(
              key: const Key('photoYear'),
              initialValue: value.year,
              decoration: const InputDecoration(
                labelText: "年",
                isDense: true,
                border: OutlineInputBorder(),
              ),
              items: [
                const DropdownMenuItem(value: null, child: Text("すべて")),
                for (final year in yearItems)
                  DropdownMenuItem(value: year, child: Text("$year年")),
              ],
              onChanged: (year) => onChanged(value.withYear(year)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: DropdownButtonFormField<int?>(
              key: Key('photoMonth-${value.year}'),
              initialValue: value.month,
              decoration: const InputDecoration(
                labelText: "月",
                isDense: true,
                border: OutlineInputBorder(),
              ),
              items: [
                const DropdownMenuItem(value: null, child: Text("すべて")),
                for (var month = 1; month <= 12; month++)
                  DropdownMenuItem(value: month, child: Text("$month月")),
              ],
              // 年を選ぶまでは、月は選べない
              onChanged: value.year == null
                  ? null
                  : (month) => onChanged(value.withMonth(month)),
            ),
          ),
        ],
      ),
    );
  }
}
