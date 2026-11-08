import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../diary/application/providers/diary_providers.dart';
import '../../../diary/domain/entities/diary.dart';
import '../../../diary/presentation/ui/diary_detail_screen.dart';
import '../../domain/services/month_grid.dart';

/// 日記を書いた日が分かるカレンダー
///
/// 日記がある日には、日記のタイトルを表示する(同じ日に複数あるときは「+1」のように件数を添える)。
/// 左右のスライドで月を変える(ホームの一覧と同じ向き。右にスライドで翌月、左にスライドで先月)
class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  // 新しい月が先頭(0番目)
  final _controller = PageController();
  var _page = 0;

  static const _weekdays = ['日', '月', '火', '水', '木', '金', '土'];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final diaries = ref.watch(diariesProvider).valueOrNull ?? const <Diary>[];

    final oldest = diaries.isEmpty
        ? null
        : diaries.map((e) => e.date).reduce((a, b) => a.isBefore(b) ? a : b);
    final months = MonthGrid.months(oldest: oldest, now: DateTime.now());

    // 日付(0時)ごとの日記
    final byDay = <DateTime, List<Diary>>{};
    for (final diary in diaries) {
      final d = diary.date;
      byDay.putIfAbsent(DateTime(d.year, d.month, d.day), () => []).add(diary);
    }

    final page = _page.clamp(0, months.length - 1);
    final month = months[page];

    return Scaffold(
      appBar: AppBar(
        title: const Text("カレンダー"),
        actions: [
          TextButton(
            onPressed: page == 0 ? null : () => _go(0),
            child: const Text("今日"),
          ),
        ],
      ),
      body: Column(
        children: [
          _monthBar(month, page, months.length),
          _weekdayRow(context),
          const Divider(height: 1),
          Expanded(
            child: PageView.builder(
              controller: _controller,
              // 新しい月が先頭のため向きを逆にして、右にスライドで翌月、左にスライドで先月にする
              reverse: true,
              itemCount: months.length,
              onPageChanged: (index) => setState(() => _page = index),
              itemBuilder: (context, index) =>
                  _monthGrid(context, months[index], byDay),
            ),
          ),
        ],
      ),
    );
  }

  void _go(int page) {
    _controller.animateToPage(
      page,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  Widget _monthBar(DateTime month, int page, int count) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          // 左が先月、右が翌月
          IconButton(
            icon: const Icon(Icons.chevron_left),
            tooltip: "先月",
            onPressed: page < count - 1 ? () => _go(page + 1) : null,
          ),
          Expanded(
            child: Text(
              "${month.year}年${month.month}月",
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            tooltip: "翌月",
            onPressed: page > 0 ? () => _go(page - 1) : null,
          ),
        ],
      ),
    );
  }

  Widget _weekdayRow(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < 7; i++)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Text(
                _weekdays[i],
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: _weekdayColor(context, i),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Color? _weekdayColor(BuildContext context, int index) {
    if (index == 0) return Colors.red;
    if (index == 6) return Colors.blue;
    return null;
  }

  Widget _monthGrid(
    BuildContext context,
    DateTime month,
    Map<DateTime, List<Diary>> byDay,
  ) {
    final cells = MonthGrid.cells(month);
    final rows = cells.length ~/ 7;

    return Column(
      children: [
        for (var r = 0; r < rows; r++)
          Expanded(
            child: Row(
              children: [
                for (var c = 0; c < 7; c++)
                  Expanded(
                    child: _cell(context, cells[r * 7 + c], c, byDay),
                  ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _cell(
    BuildContext context,
    DateTime? day,
    int column,
    Map<DateTime, List<Diary>> byDay,
  ) {
    final border = BorderSide(color: Theme.of(context).dividerColor, width: 0.5);
    final decoration = BoxDecoration(
      border: Border(bottom: border, right: border),
    );

    if (day == null) return DecoratedBox(decoration: decoration);

    final diaries = byDay[day] ?? const <Diary>[];
    final now = DateTime.now();
    final isToday = day == DateTime(now.year, now.month, now.day);
    final scheme = Theme.of(context).colorScheme;

    final cell = Container(
      decoration: decoration,
      padding: const EdgeInsets.fromLTRB(3, 3, 3, 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                decoration: isToday
                    ? BoxDecoration(
                        color: scheme.primary,
                        borderRadius: BorderRadius.circular(8),
                      )
                    : null,
                child: Text(
                  "${day.day}",
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: isToday ? scheme.onPrimary : _weekdayColor(context, column),
                  ),
                ),
              ),
              const Spacer(),
              // 同じ日に複数あるときは、2件目以降の数
              if (diaries.length > 1)
                Text(
                  "+${diaries.length - 1}",
                  style: TextStyle(fontSize: 10, color: scheme.primary),
                ),
            ],
          ),
          if (diaries.isNotEmpty)
            Expanded(
              child: Text(
                diaries.first.headline,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 10, height: 1.2),
              ),
            ),
        ],
      ),
    );

    // 日記がない日は、タップできない
    if (diaries.isEmpty) return cell;

    return InkWell(onTap: () => _open(context, day, diaries), child: cell);
  }

  // 1件ならその日記を開き、複数ならその日の一覧から選ぶ
  void _open(BuildContext context, DateTime day, List<Diary> diaries) {
    if (diaries.length == 1) {
      _openDiary(context, diaries.first);
      return;
    }

    showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                "${day.year}年${day.month}月${day.day}日の日記(${diaries.length}件)",
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            for (final diary in diaries)
              ListTile(
                title: Text(
                  diary.headline,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: diary.isAiGenerated ? const Text("AI") : null,
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  _openDiary(context, diary);
                },
              ),
          ],
        ),
      ),
    );
  }

  void _openDiary(BuildContext context, Diary diary) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => DiaryDetailScreen(diary: diary)),
    );
  }
}
