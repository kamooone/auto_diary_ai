import 'package:flutter/material.dart';
import '../../../location/domain/entities/timeline_item.dart';
import '../../../location/presentation/formatters/timeline_formatter.dart';
import '../../domain/entities/timeline_selection.dart';
import '../../domain/services/day_grouper.dart';
import '../../domain/services/timeline_text.dart';
import '../../domain/services/month_filter.dart';
import 'widgets/day_header.dart';
import 'widgets/month_header.dart';
import 'widgets/month_filter_bar.dart';

/// AIに渡す行動履歴(滞在と移動)を選択する画面
/// 「確定」で、選択した行動履歴の一覧と、住所も送ると決めた滞在を返す([TimelineSelection])
///
/// 住所(分からないときは座標)は、初めは送らない。滞在ごとに、送るかを選ぶ
class TimelineSelectPage extends StatefulWidget {
  const TimelineSelectPage({
    super.key,
    required this.items,
    required this.initialSelection,
    this.initialAddressStays = const {},
  });

  final List<TimelineItem> items;
  final List<TimelineItem> initialSelection;
  final Set<TimelineItem> initialAddressStays;

  @override
  State<TimelineSelectPage> createState() => _TimelineSelectPageState();
}

class _TimelineSelectPageState extends State<TimelineSelectPage> {
  late final _selected = {...widget.initialSelection};

  // 住所(座標)も送ると決めた滞在。初めは、どれも送らない
  late final _addressStays = {...widget.initialAddressStays};

  // 年と月による絞り込み
  var _filter = MonthFilter.none;

  late final _times = widget.items.map((e) => e.start).toList();

  // 絞り込み後の行動履歴
  List<TimelineItem> get _visible =>
      widget.items.where((e) => _filter.matches(e.start)).toList();

  // 開いている月。初めは、すべて閉じている(件数が多くても、月の一覧から選べる)
  final _expandedMonths = <DateTime>{};

  // その月の行動履歴が、すべて選択されていれば解除し、そうでなければすべて選択する
  void _toggleMonth(MonthGroup<TimelineItem> month) {
    setState(() {
      if (month.items.every(_selected.contains)) {
        _selected.removeAll(month.items);
      } else {
        _selected.addAll(month.items);
      }
    });
  }

  void _toggleExpanded(DateTime month) {
    setState(() {
      _expandedMonths.contains(month)
          ? _expandedMonths.remove(month)
          : _expandedMonths.add(month);
    });
  }

  // その日の行動履歴が、すべて選択されていれば解除し、そうでなければすべて選択する
  void _toggleDay(DayGroup<TimelineItem> day) {
    setState(() {
      if (day.items.every(_selected.contains)) {
        _selected.removeAll(day.items);
      } else {
        _selected.addAll(day.items);
      }
    });
  }

  // 住所を送るかを選べる滞在(表示中のもの)
  List<Stay> get _addressChoices =>
      _visible.whereType<Stay>().where((e) => e.canChooseAddress).toList();

  // 表示中の、住所を選べる滞在を、すべて送る・すべて送らない
  void _toggleAllAddresses(bool send) {
    setState(() {
      final stays = _addressChoices;
      send ? _addressStays.addAll(stays) : _addressStays.removeAll(stays);
    });
  }

  // 住所を送る滞在は、行の下に、送る内容を見せる
  Widget _addressSwitch(Stay stay) {
    final send = _addressStays.contains(stay);
    final isEstimated = stay.isPlaceEstimated;

    return SwitchListTile(
      dense: true,
      contentPadding: const EdgeInsets.only(left: 72, right: 16),
      title: const Text("住所も送る"),
      subtitle: Text(
        send
            ? "送る内容: ${TimelineText.addressOf(stay)}"
            : (isEstimated ? "送らない(施設名だけを送ります)" : "送らない(場所は、AIに伝わりません)"),
      ),
      value: send,
      onChanged: (value) => setState(() {
        value ? _addressStays.add(stay) : _addressStays.remove(stay);
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final visible = _visible;
    final addressChoices = _addressChoices;
    final isAllSelected = visible.every(_selected.contains);

    // 月ごとの見出し、日付ごとの見出し、行動履歴を、1列に並べたもの
    final rows = buildMonthRows<TimelineItem>(
      groupByDay<TimelineItem>(visible, (e) => e.start),
      _expandedMonths,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text("行動履歴 (${_selected.length}/${widget.items.length})"),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                if (isAllSelected) {
                  _selected.removeAll(visible);
                } else {
                  _selected.addAll(visible);
                }
              });
            },
            child: Text(
              _filter.isActive
                  ? (isAllSelected ? "表示中を解除" : "表示中を選択")
                  : (isAllSelected ? "すべて解除" : "すべて選択"),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          MonthFilterBar(
            times: _times,
            value: _filter,
            onChanged: (filter) => setState(() => _filter = filter),
          ),
          // 住所は、初めは送らない。送るかどうかを、利用者が決める
          Container(
            width: double.infinity,
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Text(
              "住所が必要な滞在だけ、選んだあとに出る「住所も送る」を、オンにしてください。\n"
              "旅行に行ったときなどは、住所も送ると、AIがより詳しく日記を書いてくれます。\n"
              "送ってよい住所: 旅行先や、お出かけ先など、個人情報に関係しない場所\n"
              "送らない方がよい住所: 自宅、職場、学校など、あなたの個人情報にあたる場所",
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          if (addressChoices.isNotEmpty)
            SwitchListTile(
              dense: true,
              title: const Text("表示中の滞在の住所を、すべて送る"),
              value: addressChoices.every(_addressStays.contains),
              onChanged: _toggleAllAddresses,
            ),
          Expanded(
            child: ListView.builder(
              itemCount: rows.length,
              itemBuilder: (context, index) {
                final row = rows[index];

                // 月の見出し
                if (row is MonthGroup<TimelineItem>) {
                  return MonthHeader(
                    month: row.month,
                    selectedCount: row.items.where(_selected.contains).length,
                    totalCount: row.items.length,
                    onToggle: () => _toggleMonth(row),
                    isExpanded: _expandedMonths.contains(row.month),
                    onTap: () => _toggleExpanded(row.month),
                  );
                }

                // 日付の見出し
                if (row is DayGroup<TimelineItem>) {
                  return DayHeader(
                    date: row.date,
                    selectedCount: row.items.where(_selected.contains).length,
                    totalCount: row.items.length,
                    onToggle: () => _toggleDay(row),
                  );
                }

                final item = row as TimelineItem;
                final time = TimelineFormatter.timeRange(item);

                final tile = CheckboxListTile(
                  dense: true,
                  value: _selected.contains(item),
                  secondary: Icon(switch (item) {
                    Stay() => Icons.place,
                    Move() => TimelineFormatter.transportIcon(item.transport),
                    RecordingOff() => Icons.pause_circle_outline,
                  }),
                  title: Text(switch (item) {
                    Stay() => TimelineFormatter.stayTitle(item),
                    Move() => TimelineFormatter.moveTitle(item),
                    RecordingOff() => TimelineFormatter.recordingOffTitle,
                  }),
                  subtitle: Text(switch (item) {
                    Stay() =>
                      "$time（${TimelineFormatter.duration(item.duration)}）",
                    Move() || RecordingOff() => time,
                  }),
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

                // 選んだ滞在で、住所を送るかを選べるものは、下にスイッチを出す
                if (item is Stay &&
                    item.canChooseAddress &&
                    _selected.contains(item)) {
                  return Column(children: [tile, _addressSwitch(item)]);
                }
                return tile;
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: ElevatedButton(
            // 時系列の並び順のまま返す
            onPressed: () {
              final items = widget.items.where(_selected.contains).toList();
              Navigator.of(context).pop(
                TimelineSelection(
                  items: items,
                  // 選んだ滞在のうち、住所も送ると決めたものだけ
                  addressStays: {
                    for (final item in items)
                      if (_addressStays.contains(item)) item,
                  },
                ),
              );
            },
            child: Text("確定（${_selected.length}件）"),
          ),
        ),
      ),
    );
  }
}
