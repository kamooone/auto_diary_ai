import 'package:flutter/material.dart';
import '../../../diary/domain/entities/diary.dart';
import '../../domain/services/day_grouper.dart';
import '../../domain/services/month_filter.dart';
import '../../domain/services/summary_text.dart';
import 'widgets/day_header.dart';
import 'widgets/month_header.dart';
import 'widgets/month_filter_bar.dart';

/// まとめ日記の材料にする、作成済みの日記を選択する画面
/// 「確定」で選択した日記の一覧を返す
class DiarySelectPage extends StatefulWidget {
  const DiarySelectPage({
    super.key,
    required this.diaries,
    required this.initialSelection,
  });

  final List<Diary> diaries;
  final List<Diary> initialSelection;

  @override
  State<DiarySelectPage> createState() => _DiarySelectPageState();
}

class _DiarySelectPageState extends State<DiarySelectPage> {
  late final _selectedIds = {for (final e in widget.initialSelection) e.id};

  // 年と月による絞り込み
  var _filter = MonthFilter.none;

  late final _times = widget.diaries.map((e) => e.date).toList();

  // 開いている月。初めは、すべて閉じている(件数が多くても、月の一覧から選べる)
  final _expandedMonths = <DateTime>{};

  List<Diary> get _selected =>
      widget.diaries.where((e) => _selectedIds.contains(e.id)).toList();

  // 絞り込み後の日記
  List<Diary> get _visible =>
      widget.diaries.where((e) => _filter.matches(e.date)).toList();

  void _select(Iterable<Diary> diaries) =>
      _selectedIds.addAll(diaries.map((e) => e.id));

  void _unselect(Iterable<Diary> diaries) =>
      _selectedIds.removeAll(diaries.map((e) => e.id));

  bool _isSelected(Diary diary) => _selectedIds.contains(diary.id);

  // その月の日記が、すべて選択されていれば解除し、そうでなければすべて選択する
  void _toggleMonth(MonthGroup<Diary> month) {
    setState(() {
      month.items.every(_isSelected)
          ? _unselect(month.items)
          : _select(month.items);
    });
  }

  void _toggleExpanded(DateTime month) {
    setState(() {
      _expandedMonths.contains(month)
          ? _expandedMonths.remove(month)
          : _expandedMonths.add(month);
    });
  }

  @override
  Widget build(BuildContext context) {
    final visible = _visible;
    final isAllSelected = visible.isNotEmpty && visible.every(_isSelected);
    final selected = _selected;
    final chars = SummaryText.length(selected);
    final isTooLong = chars > SummaryText.maxChars;

    // 1件だけでは1つの日記にならないので、確定できない(0件に戻すのはかまわない)
    final isTooFew = selected.length == 1;

    // 月ごとの見出し、日付ごとの見出し、日記を、1列に並べたもの
    final rows = buildMonthRows<Diary>(
      groupByDay<Diary>(visible, (e) => e.date),
      _expandedMonths,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text("日記 (${selected.length}/${widget.diaries.length})"),
        actions: [
          TextButton(
            onPressed: visible.isEmpty
                ? null
                : () {
                    setState(() {
                      isAllSelected ? _unselect(visible) : _select(visible);
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
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isTooFew)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    "日記を${SummaryText.minCount}件以上選んでください",
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
              if (isTooLong)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    "選んだ日記が長すぎます(${_comma(chars)}文字/"
                    "上限${_comma(SummaryText.maxChars)}文字)。件数を減らしてください",
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isTooLong || isTooFew
                      ? null
                      : () => Navigator.of(context).pop(selected),
                  child: Text("確定（${selected.length}件）"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _list(List<Object> rows) {
    return ListView.separated(
      itemCount: rows.length,
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final row = rows[index];

        // 月の見出し
        if (row is MonthGroup<Diary>) {
          return MonthHeader(
            month: row.month,
            selectedCount: row.items.where(_isSelected).length,
            totalCount: row.items.length,
            onToggle: () => _toggleMonth(row),
            isExpanded: _expandedMonths.contains(row.month),
            onTap: () => _toggleExpanded(row.month),
          );
        }

        // 日付の見出し
        if (row is DayGroup<Diary>) {
          // 日記は1日に1件のことが多いため、日ごとの全選択は付けない(月ごとの全選択がある)
          return DayHeader(
            date: row.date,
            selectedCount: row.items.where(_isSelected).length,
            totalCount: row.items.length,
          );
        }

        final diary = row as Diary;

        return CheckboxListTile(
          value: _isSelected(diary),
          title: Text(
            diary.headline.isEmpty ? "(タイトルなし)" : diary.headline,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text(
            diary.content.trim(),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          onChanged: (checked) {
            setState(() {
              (checked ?? false) ? _select([diary]) : _unselect([diary]);
            });
          },
        );
      },
    );
  }

  String _comma(int number) => number.toString().replaceAllMapped(
    RegExp(r'(\d)(?=(\d{3})+$)'),
    (m) => "${m[1]},",
  );
}
