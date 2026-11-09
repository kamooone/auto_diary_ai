import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../diary_create/domain/entities/photo.dart';
import '../../../diary_create/presentation/ui/widgets/photo_thumbnail.dart';
import '../../application/providers/memo_providers.dart';
import '../../domain/entities/memo.dart';
import 'memo_edit_dialog.dart';

/// ホーム画面の「ひとこと」タブ。ひとことメモを、新しい順に並べる
class MemoListView extends ConsumerWidget {
  const MemoListView({super.key});

  static const _weekdays = ['月', '火', '水', '木', '金', '土', '日'];

  /// 「2026年11月9日（月） 12:34」の形
  static String dateTimeText(DateTime t) {
    final minute = t.minute.toString().padLeft(2, '0');

    return "${t.year}年${t.month}月${t.day}日（${_weekdays[t.weekday - 1]}） "
        "${t.hour}:$minute";
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final memos = ref.watch(allMemosProvider);

    return memos.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => const Center(child: Text("読み込めませんでした")),
      data: (memos) {
        if (memos.isEmpty) {
          return const Center(
            child: Text(
              "まだひとことメモがありません\n右下のボタンから追加できます",
              textAlign: TextAlign.center,
            ),
          );
        }

        return ListView.separated(
          // 右下のボタンに、最後のメモが隠れないようにする
          padding: const EdgeInsets.only(bottom: 88),
          itemCount: memos.length,
          separatorBuilder: (context, index) => const Divider(height: 1),
          itemBuilder: (context, index) => _MemoTile(memo: memos[index]),
        );
      },
    );
  }
}

class _MemoTile extends ConsumerWidget {
  const _MemoTile({required this.memo});

  final Memo memo;

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
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
    return InkWell(
      onTap: () => showMemoEditDialog(context, memo: memo),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 4, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    MemoListView.dateTimeText(memo.createdAt),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                ),
                PopupMenuButton<String>(
                  tooltip: "メニュー",
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
              padding: const EdgeInsets.only(right: 12),
              child: Text(memo.text),
            ),
            if (memo.photoIds.isNotEmpty) ...[
              const SizedBox(height: 8),
              SizedBox(
                height: 80,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: memo.photoIds.length,
                  separatorBuilder: (context, index) => const SizedBox(width: 6),
                  itemBuilder: (context, index) => SizedBox(
                    width: 80,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
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
    );
  }
}
