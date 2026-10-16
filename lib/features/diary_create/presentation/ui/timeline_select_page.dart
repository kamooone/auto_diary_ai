import 'package:flutter/material.dart';
import '../../../location/domain/entities/timeline_item.dart';
import '../../../location/presentation/formatters/timeline_formatter.dart';
import '../../domain/services/timeline_day_grouper.dart';

/// AIに渡す行動履歴(滞在と移動)を選択する画面
/// 「確定」で選択した行動履歴の一覧を返す
class TimelineSelectPage extends StatefulWidget {
  const TimelineSelectPage({
    super.key,
    required this.items,
    required this.initialSelection,
  });

  final List<TimelineItem> items;
  final List<TimelineItem> initialSelection;

  @override
  State<TimelineSelectPage> createState() => _TimelineSelectPageState();
}

class _TimelineSelectPageState extends State<TimelineSelectPage> {
  late final _selected = {...widget.initialSelection};

  // 日付ごとの見出しと行動履歴を、1列に並べたもの
  late final List<Object> _rows = [
    for (final day in TimelineDayGrouper().group(widget.items)) ...[
      day.date,
      ...day.items,
    ],
  ];

  static const _weekdays = ['月', '火', '水', '木', '金', '土', '日'];

  String _dateText(DateTime date) {
    return "${date.year}年${date.month}月${date.day}日"
        "（${_weekdays[date.weekday - 1]}）";
  }

  @override
  Widget build(BuildContext context) {
    final isAllSelected = _selected.length == widget.items.length;

    return Scaffold(
      appBar: AppBar(
        title: Text("行動履歴 (${_selected.length}/${widget.items.length})"),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                if (isAllSelected) {
                  _selected.clear();
                } else {
                  _selected.addAll(widget.items);
                }
              });
            },
            child: Text(isAllSelected ? "すべて解除" : "すべて選択"),
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: _rows.length,
        itemBuilder: (context, index) {
          final row = _rows[index];

          // 日付の見出し
          if (row is DateTime) {
            return Container(
              width: double.infinity,
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                _dateText(row),
                style: Theme.of(context).textTheme.titleSmall,
              ),
            );
          }

          final item = row as TimelineItem;
          final time = TimelineFormatter.timeRange(item);

          return CheckboxListTile(
            dense: true,
            value: _selected.contains(item),
            secondary: Icon(
              switch (item) {
                Stay() => Icons.place,
                Move() => TimelineFormatter.transportIcon(item.transport),
                RecordingOff() => Icons.pause_circle_outline,
              },
            ),
            title: Text(
              switch (item) {
                Stay() => TimelineFormatter.stayTitle(item),
                Move() => TimelineFormatter.moveTitle(item),
                RecordingOff() => TimelineFormatter.recordingOffTitle,
              },
            ),
            subtitle: Text(
              switch (item) {
                Stay() =>
                  "$time（${TimelineFormatter.duration(item.duration)}）",
                Move() || RecordingOff() => time,
              },
            ),
            onChanged: (checked) {
              setState(() {
                if (checked ?? false) {
                  _selected.add(item);
                } else {
                  _selected.remove(item);
                }
              });
            },
          );
        },
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: ElevatedButton(
            // 時系列の並び順のまま返す
            onPressed: () => Navigator.of(context).pop(
              widget.items.where(_selected.contains).toList(),
            ),
            child: Text("確定（${_selected.length}件）"),
          ),
        ),
      ),
    );
  }
}
