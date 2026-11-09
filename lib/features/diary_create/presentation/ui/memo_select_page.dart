import 'package:flutter/material.dart';
import '../../../memo/domain/entities/memo.dart';
import '../../domain/services/day_grouper.dart';
import '../../domain/services/month_filter.dart';
import 'widgets/day_header.dart';
import 'widgets/month_header.dart';
import 'widgets/month_filter_bar.dart';

/// AIに渡すひとことメモを選択する画面
/// 「確定」で選択したメモの一覧を返す
class MemoSelectPage extends StatefulWidget {
  const MemoSelectPage({
    super.key,
    required this.memos,
    required this.initialSelection,
  });

  final List<Memo> memos;
  final List<Memo> initialSelection;

  @override
  State<MemoSelectPage> createState() => _MemoSelectPageState();
}

class _MemoSelectPageState extends State<MemoSelectPage> {
  late final _selected = {...widget.initialSelection};

  // 年と月による絞り込み
  var _filter = MonthFilter.none;

  late final _times = widget.memos.map((e) => e.createdAt).toList();

  // 絞り込み後のメモ
  List<Memo> get _visible =>
      widget.memos.where((e) => _filter.matches(e.createdAt)).toList();

  // 開いている月。初めは、すべて閉じている(件数が多くても、月の一覧から選べる)
  final _expandedMonths = <DateTime>{};

  // その月のメモが、すべて選択されていれば解除し、そうでなければすべて選択する
  void _toggleMonth(MonthGroup<Memo> month) {
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

  // その日のメモが、すべて選択されていれば解除し、そうでなければすべて選択する
  void _toggleDay(DayGroup<Memo> day) {
    setState(() {
      if (day.items.every(_selected.contains)) {
        _selected.removeAll(day.items);
      } else {
        _selected.addAll(day.items);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final visible = _visible;
    final isAllSelected = visible.every(_selected.contains);

    // 月ごとの見出し、日付ごとの見出し、メモを、1列に並べたもの
    final rows = buildMonthRows<Memo>(
      groupByDay<Memo>(visible, (e) => e.createdAt),
      _expandedMonths,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text("ひとことメモ (${_selected.length}/${widget.memos.length})"),
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
          Expanded(child: _list(rows)),
        ],
      ),
      bottomNavigationBar: _confirmBar(context),
    );
  }

  Widget _list(List<Object> rows) {
    return ListView.separated(
      itemCount: rows.length,
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final row = rows[index];

        // 月の見出し
        if (row is MonthGroup<Memo>) {
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
        if (row is DayGroup<Memo>) {
          return DayHeader(
            date: row.date,
            selectedCount: row.items.where(_selected.contains).length,
            totalCount: row.items.length,
            onToggle: () => _toggleDay(row),
          );
        }

        final memo = row as Memo;

        return CheckboxListTile(
          value: _selected.contains(memo),
          title: Text(
            memo.text,
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text(_time(memo.createdAt)),
          onChanged: (checked) {
            setState(() {
              if (checked ?? false) {
                _selected.add(memo);
              } else {
                _selected.remove(memo);
              }
            });
          },
        );
      },
    );
  }

  Widget _confirmBar(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        child: ElevatedButton(
          // 元の並び順のまま返す
          onPressed: () => Navigator.of(
            context,
          ).pop(widget.memos.where(_selected.contains).toList()),
          child: Text("確定（${_selected.length}件）"),
        ),
      ),
    );
  }

  String _time(DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return "${time.month}/${time.day} $hour:$minute";
  }
}
