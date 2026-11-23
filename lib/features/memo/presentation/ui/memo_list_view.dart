import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:auto_diary_ai/common/constants/app_colors.dart';
import 'package:auto_diary_ai/common/constants/app_sizes.dart';
import 'package:auto_diary_ai/common/widgets/month_bar.dart';
import 'package:auto_diary_ai/common/widgets/timeline_row.dart';
import 'package:auto_diary_ai/features/home/domain/services/home_months.dart';
import 'package:auto_diary_ai/features/home/presentation/ui/widgets/trail_illustration.dart';
import '../../../diary_create/domain/entities/photo.dart';
import '../../../diary_create/presentation/ui/widgets/photo_thumbnail.dart';
import '../../application/providers/memo_providers.dart';
import '../../domain/entities/memo.dart';
import '../../domain/services/memo_filter.dart';
import '../../domain/services/memo_timeline.dart';
import 'memo_edit_dialog.dart';

/// ホーム画面の「ひとこと」タブ。ひとことメモを、新しい順に並べる
///
/// 上の月の切り替え(日記の一覧と同じ)で、月ごとに見られる。検索の入力欄に書くと、すべての月から探す
class MemoListView extends ConsumerStatefulWidget {
  const MemoListView({super.key});

  @override
  ConsumerState<MemoListView> createState() => _MemoListViewState();
}

class _MemoListViewState extends ConsumerState<MemoListView> {
  // 新しい月が先頭(0番目)。日記の一覧と同じ向き
  final _controller = PageController();

  // 表示中の月(「2026-10」の形)。選んでいないときは、いちばん新しい月(今月)
  String? _selected;
  var _query = '';
  var _monthCount = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  static String _monthKey(DateTime t) =>
      '${t.year}-${t.month.toString().padLeft(2, '0')}';

  void _goTo(List<String> months, String month) {
    final index = months.indexOf(month);
    if (index < 0) return;

    setState(() => _selected = month);
    _controller.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final memos = ref.watch(allMemosProvider);

    return memos.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => const Center(child: Text("読み込めませんでした")),
      data: (memos) {
        if (memos.isEmpty) {
          return const Center(
            child: SingleChildScrollView(
              child: TrailIllustration(
                message: "まだひとことメモがありません\n右下のボタンから追加できます",
              ),
            ),
          );
        }

        // 今月から、いちばん古いメモの月まで(メモのない月も含める。新しい月が先頭)
        final months = homeMonths(
          diaryDates: memos.map((e) => e.createdAt),
          now: DateTime.now(),
        );
        final selected = _selected != null && months.contains(_selected)
            ? _selected!
            : months.first;

        // メモが増えて、月の数が変わったときは、表示中の月のページに合わせ直す
        if (_monthCount != months.length) {
          _monthCount = months.length;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (_controller.hasClients) {
              _controller.jumpToPage(months.indexOf(selected));
            }
          });
        }

        final searching = _query.trim().isNotEmpty;

        return Column(
          children: [
            // 検索しているときは、すべての月から探すので、月の切り替えは隠す
            if (!searching)
              MonthBar(
                months: months,
                selectedMonth: selected,
                onChanged: (month) => _goTo(months, month),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: TextField(
                key: const Key('memoSearch'),
                decoration: const InputDecoration(
                  hintText: "メモを検索",
                  prefixIcon: Icon(Icons.search),
                  isDense: true,
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) => setState(() => _query = value),
              ),
            ),
            Expanded(
              child: searching
                  ? _searchResult(memos)
                  : PageView.builder(
                      controller: _controller,
                      // 新しい月が先頭のため向きを逆にして、右にスライドで翌月、左にスライドで先月にする
                      reverse: true,
                      itemCount: months.length,
                      onPageChanged: (index) =>
                          setState(() => _selected = months[index]),
                      itemBuilder: (context, index) => _monthPage(
                        memos
                            .where(
                              (e) => _monthKey(e.createdAt) == months[index],
                            )
                            .toList(),
                      ),
                    ),
            ),
          ],
        );
      },
    );
  }

  // 検索の結果(すべての月から)
  Widget _searchResult(List<Memo> memos) {
    final shown = MemoFilter.apply(memos, query: _query);
    if (shown.isEmpty) {
      return const Center(
        child: Text(
          "条件に合うメモがありません",
          style: TextStyle(color: AppColors.textSub),
        ),
      );
    }
    return _MemoTimeline(items: buildMemoTimeline(shown));
  }

  // 1か月分のページ(その月にメモがなければ、小さな絵と一文)
  Widget _monthPage(List<Memo> items) {
    if (items.isEmpty) {
      return ListView(
        padding: const EdgeInsets.only(bottom: 96),
        children: const [
          TrailIllustration(message: "この月は、まだひとことがありません\n右下のボタンから追加できます"),
        ],
      );
    }
    return _MemoTimeline(items: buildMemoTimeline(items));
  }
}

/// ひとことのタイムライン(左に日付、縦の点線、右にカード。月が変わるところに、月の見出し)
class _MemoTimeline extends StatelessWidget {
  const _MemoTimeline({required this.items});

  final List<MemoTimelineItem> items;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      // 右下のボタンに、最後のメモが隠れないようにする
      padding: const EdgeInsets.fromLTRB(
        AppSizes.space16,
        AppSizes.space4,
        AppSizes.space16,
        96,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        final t = item.memo.createdAt;
        final next = index + 1 < items.length ? items[index + 1] : null;

        return Column(
          children: [
            if (item.showMonth)
              // 月の見出し(点線は、見出しの横も、つなぐ)
              TimelineRow(
                date: t,
                showDate: false,
                bottomGap: AppSizes.space8,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '${t.year}年${t.month}月',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                      color: AppColors.navyDark,
                    ),
                  ),
                ),
              ),
            TimelineRow(
              date: t,
              showDate: item.showDate,
              // 違う日の間は広く、同じ日のメモどうしは、近くに置く
              bottomGap: next != null && next.showDate && !next.showMonth
                  ? AppSizes.space24
                  : next != null && next.showMonth
                  ? AppSizes.space16
                  : AppSizes.space12,
              child: _MemoCard(memo: item.memo),
            ),
          ],
        );
      },
    );
  }
}

class _MemoCard extends ConsumerWidget {
  const _MemoCard({required this.memo});

  final Memo memo;

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        scrollable: true,
        title: const Text("このメモを削除しますか？"),
        content: const Text("削除したメモは、元に戻せません。"),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text("キャンセル"),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text("削除する"),
          ),
        ],
      ),
    );

    final id = memo.id;
    if (ok != true || id == null) return;

    await ref.read(memoRepositoryProvider).delete(id);
    ref.invalidate(allMemosProvider);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = memo.createdAt;
    final time = '${t.hour}:${t.minute.toString().padLeft(2, '0')}';
    final radius = BorderRadius.circular(AppSizes.radius16);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: radius,
        boxShadow: AppColors.cardShadows,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: radius,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => showMemoEditDialog(context, memo: memo),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSizes.space16,
              AppSizes.space4,
              AppSizes.space4,
              AppSizes.space12,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        time,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w400,
                          color: AppColors.textSub,
                        ),
                      ),
                    ),
                    PopupMenuButton<String>(
                      tooltip: "メニュー",
                      icon: const Icon(
                        Icons.more_vert,
                        color: AppColors.chevron,
                      ),
                      onSelected: (value) {
                        if (value == 'edit') {
                          showMemoEditDialog(context, memo: memo);
                        } else {
                          _delete(context, ref);
                        }
                      },
                      itemBuilder: (context) => const [
                        PopupMenuItem(value: 'edit', child: Text("修正")),
                        PopupMenuItem(value: 'delete', child: Text("削除")),
                      ],
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.only(right: AppSizes.space12),
                  child: Text(
                    memo.text,
                    style: const TextStyle(
                      fontSize: 14,
                      height: 1.5,
                      color: AppColors.text,
                    ),
                  ),
                ),
                if (memo.photoIds.isNotEmpty) ...[
                  const SizedBox(height: AppSizes.space8),
                  SizedBox(
                    height: 72,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: memo.photoIds.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(width: AppSizes.space8),
                      itemBuilder: (context, index) => SizedBox(
                        width: 72,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(
                            AppSizes.radius12,
                          ),
                          child: PhotoThumbnail(
                            photo: Photo(
                              id: memo.photoIds[index],
                              createdAt: memo.createdAt,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
