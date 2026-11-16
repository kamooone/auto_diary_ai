import 'package:flutter/material.dart';
import 'package:auto_diary_ai/common/constants/app_colors.dart';
import 'package:auto_diary_ai/common/constants/app_sizes.dart';
import 'package:auto_diary_ai/common/widgets/month_bar.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../diary/application/providers/diary_providers.dart';
import '../../../diary/domain/entities/diary.dart';
import '../../../diary/presentation/ui/diary_detail_screen.dart';
import '../../../tutorial/application/tutorial_providers.dart';
import '../../../tutorial/domain/tutorial_step.dart';
import '../../../tutorial/presentation/tutorial_runner.dart';
import '../../domain/services/month_grid.dart';
import 'widgets/calendar_day_cell.dart';

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

  // チュートリアルで明るくする部品
  final _calendarKey = GlobalKey();

  // この画面のチュートリアルの印(見たかどうかを覚えるときの名前)
  static const _tutorialId = 'calendar';

  static const _weekdays = ['日', '月', '火', '水', '木', '金', '土'];

  // 日付のマス
  static const _sidePadding = 12.0;
  static const _gap = 4.0;
  static const _cellHeight = 114.0;
  static const _minCellHeight = 96.0;

  // マスの下の、説明の行の高さ(上の間隔8を除く。収まるかの計算に使う)
  static const _legendHeight = 8.0 + 20.0 + 16.0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _showTutorialOnce());
  }

  // 初めて表示したときだけ、1ページで説明する
  Future<void> _showTutorialOnce() async {
    final store = ref.read(tutorialSeenStoreProvider);
    if (await store.hasSeen(_tutorialId)) return;
    if (!mounted) return;

    await showTutorial(context, [
      TutorialStep(
        target: _calendarKey,
        title: "カレンダー",
        bubbleCenter: true,
        body:
            "日記がある日に、日記のタイトルが表示されます。\nタップすると、その日の日記を確認できます。\n同じ日に複数あるときは、「+1」のように件数が表示されます。",
      ),
    ]);

    await store.markSeen(_tutorialId);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  static String _monthKey(DateTime month) =>
      '${month.year}-${month.month.toString().padLeft(2, '0')}';

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

    // いちばん新しい記録の日
    final latestDay = byDay.keys.isEmpty
        ? null
        : byDay.keys.reduce((a, b) => a.isAfter(b) ? a : b);

    final page = _page.clamp(0, months.length - 1);
    final month = months[page];
    final monthKeys = [for (final m in months) _monthKey(m)];

    // その月に、日記を書いた日の数
    final recordedDays = byDay.keys
        .where((d) => d.year == month.year && d.month == month.month)
        .length;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: '戻る',
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: const Text(
          'カレンダー',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.72,
            color: AppColors.white,
          ),
        ),
        actions: [
          TextButton(
            onPressed: page == 0 ? null : () => _go(0),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.white,
              disabledForegroundColor: AppColors.white.withValues(alpha: 0.5),
              minimumSize: const Size(44, 44),
            ),
            child: const Text('今日'),
          ),
        ],
      ),
      body: Column(
        key: _calendarKey,
        children: [
          // 年月の切り替え(ホーム画面と共通)
          MonthBar(
            compact: true,
            months: monthKeys,
            selectedMonth: _monthKey(month),
            recordedDays: recordedDays,
            onChanged: (key) {
              final index = monthKeys.indexOf(key);
              if (index >= 0) _go(index);
            },
          ),
          _weekdayRow(),
          Expanded(
            child: PageView.builder(
              controller: _controller,
              // 新しい月が先頭のため向きを逆にして、右にスライドで翌月、左にスライドで先月にする
              reverse: true,
              itemCount: months.length,
              onPageChanged: (index) => setState(() => _page = index),
              itemBuilder: (context, index) =>
                  _monthPage(months[index], byDay, latestDay),
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

  // 曜日の行(日付のマスと、同じ幅・同じ間隔で並べる)
  Widget _weekdayRow() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        _sidePadding,
        0,
        _sidePadding,
        AppSizes.space4,
      ),
      child: Row(
        children: [
          for (var i = 0; i < 7; i++) ...[
            if (i > 0) const SizedBox(width: _gap),
            Expanded(
              child: Text(
                _weekdays[i],
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: i == 0
                      ? AppColors.sunday
                      : i == 6
                      ? AppColors.saturday
                      : AppColors.textSub,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// 1か月分のページ。6週にまたがる月は、マスの高さを縮めて、1画面に収める(それでも収まらなければ、縦にスクロール)
  Widget _monthPage(
    DateTime month,
    Map<DateTime, List<Diary>> byDay,
    DateTime? latestDay,
  ) {
    final cells = MonthGrid.cells(month);
    final rows = cells.length ~/ 7;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    return LayoutBuilder(
      builder: (context, constraints) {
        final gaps = (rows - 1) * _gap;
        final available = constraints.maxHeight - _legendHeight - gaps;
        final cellHeight = (available / rows).clamp(
          _minCellHeight,
          _cellHeight,
        );

        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            _sidePadding,
            0,
            _sidePadding,
            AppSizes.space16,
          ),
          child: Column(
            children: [
              for (var r = 0; r < rows; r++) ...[
                if (r > 0) const SizedBox(height: _gap),
                SizedBox(
                  height: cellHeight,
                  child: Row(
                    children: [
                      for (var c = 0; c < 7; c++) ...[
                        if (c > 0) const SizedBox(width: _gap),
                        Expanded(
                          child: _cell(
                            cells[r * 7 + c],
                            c,
                            byDay,
                            latestDay,
                            today,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
              const SizedBox(height: AppSizes.space8),
              const _Legend(),
            ],
          ),
        );
      },
    );
  }

  Widget _cell(
    DateTime? day,
    int column,
    Map<DateTime, List<Diary>> byDay,
    DateTime? latestDay,
    DateTime today,
  ) {
    // その月以外の日(前後の空き)は、何も表示しない
    if (day == null) return const SizedBox.shrink();

    final diaries = byDay[day] ?? const <Diary>[];

    return CalendarDayCell(
      day: day,
      column: column,
      diaries: diaries,
      isLatest: latestDay != null && day == latestDay,
      isToday: day == today,
      onTap: () => _open(context, day, diaries),
    );
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

/// マスの下の、説明の行(「記録した日」「いちばん新しい記録」「ほかの日記の数」)
class _Legend extends StatelessWidget {
  const _Legend();

  @override
  Widget build(BuildContext context) {
    const style = TextStyle(fontSize: 12, color: AppColors.textSub);

    Widget item(Widget mark, String label) => Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        mark,
        const SizedBox(width: 6),
        Text(label, style: style),
      ],
    );

    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: AppSizes.space16,
      runSpacing: AppSizes.space4,
      children: [
        item(
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: AppColors.line),
            ),
          ),
          '記録した日',
        ),
        item(
          Container(
            width: 12,
            height: 12,
            decoration: const BoxDecoration(
              color: AppColors.orange,
              shape: BoxShape.circle,
            ),
          ),
          'いちばん新しい記録',
        ),
        item(const ExcludeSemantics(child: MoreChip(count: 1)), 'ほかの日記の数'),
      ],
    );
  }
}
