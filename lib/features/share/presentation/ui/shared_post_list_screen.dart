import 'package:flutter/material.dart';
import '../../../ads/presentation/ad_top_layout.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../common/constants/app_colors.dart';
import '../../../../common/constants/app_sizes.dart';
import '../../../../common/widgets/app_card.dart';
import '../../../../common/widgets/icon_action_button.dart';
import '../../../diary_create/domain/entities/photo.dart';
import '../../../diary_create/domain/services/day_grouper.dart';
import '../../../diary_create/domain/services/month_filter.dart';
import '../../../diary_create/presentation/ui/widgets/month_filter_bar.dart';
import '../../../diary_create/presentation/ui/widgets/photo_strip.dart';
import '../../../diary_create/presentation/ui/widgets/photo_viewer_page.dart';
import '../../application/providers/share_providers.dart';
import '../../domain/entities/shared_post.dart';
import '../formatters/shared_post_format.dart';
import 'shared_post_edit_screen.dart';
import 'x_share_guide_page.dart';

/// 保存したXの投稿の一覧(設定画面から開く)
/// 投稿の削除、内容の修正、日時の変更ができる
class SharedPostListScreen extends ConsumerWidget {
  const SharedPostListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final posts = ref.watch(allSharedPostsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Xの投稿一覧"),
        actions: [
          // 投稿が1件もないときも、保存のしかたを確認できるようにする
          IconButton(
            tooltip: "Xから共有する方法",
            icon: const Icon(Icons.help_outline),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const XShareGuidePage()),
            ),
          ),
        ],
      ),
      body: AdTopLayout(
        child: posts.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => const Center(child: Text("投稿を読み込めませんでした")),
          data: (posts) {
            if (posts.isEmpty) {
              return const Center(child: Text("保存したXの投稿はありません"));
            }

            return _PostList(posts: posts);
          },
        ),
      ),
    );
  }
}

class _PostList extends ConsumerStatefulWidget {
  const _PostList({required this.posts});

  final List<SharedPost> posts;

  @override
  ConsumerState<_PostList> createState() => _PostListState();
}

class _PostListState extends ConsumerState<_PostList> {
  // 年と月による絞り込み
  var _filter = MonthFilter.none;

  @override
  Widget build(BuildContext context) {
    // 削除などで、選んでいた月の投稿がなくなったときは、絞り込みを外す
    final times = widget.posts.map((e) => e.receivedAt).toList();
    final filter = times.any(_filter.matches) ? _filter : MonthFilter.none;
    final visible = widget.posts.where((e) => filter.matches(e.receivedAt));

    // 日付の新しい順に、見出しと投稿を1列に並べる
    final rows = <Object>[
      for (final day in groupByDay<SharedPost>(
        visible.toList(),
        (e) => e.receivedAt,
      ).reversed) ...[day.date, ...day.items],
    ];

    return Column(
      children: [
        MonthFilterBar(
          times: times,
          value: filter,
          onChanged: (value) => setState(() => _filter = value),
          chipStyle: true,
        ),
        Expanded(child: _list(context, rows)),
      ],
    );
  }

  Widget _list(BuildContext context, List<Object> rows) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(
        AppSizes.space16,
        AppSizes.space8,
        AppSizes.space16,
        AppSizes.space24,
      ),
      itemCount: rows.length,
      itemBuilder: (context, index) {
        final row = rows[index];

        // 日付ごとの見出し
        if (row is DateTime) {
          return Padding(
            padding: EdgeInsets.fromLTRB(
              AppSizes.space4,
              index == 0 ? 0 : AppSizes.space16,
              AppSizes.space4,
              AppSizes.space8,
            ),
            child: Text(
              SharedPostFormat.date(row),
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.textSub,
              ),
            ),
          );
        }

        final post = row as SharedPost;

        return Padding(
          padding: const EdgeInsets.only(bottom: AppSizes.space8),
          child: AppCard(
            child: InkWell(
              onTap: () async {
                final changed = await Navigator.of(context).push<bool>(
                  MaterialPageRoute(
                    builder: (context) => SharedPostEditScreen(post: post),
                  ),
                );

                if (changed == true) ref.invalidate(allSharedPostsProvider);
              },
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 8, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            SharedPostFormat.time(post.receivedAt),
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSub,
                              fontFeatures: [FontFeature.tabularFigures()],
                            ),
                          ),
                        ),
                        IconActionButton(
                          icon: Icons.delete_outline,
                          label: "削除",
                          onPressed: () => _confirmDelete(context, ref, post),
                        ),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.only(right: AppSizes.space8),
                      child: Text(
                        post.text.isEmpty ? "(テキストなし)" : post.text,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 15,
                          height: 1.7,
                          color: AppColors.text,
                        ),
                      ),
                    ),
                    if (post.photoIds.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(
                          top: AppSizes.space8,
                          bottom: AppSizes.space8,
                        ),
                        child: Builder(
                          builder: (context) {
                            final photos = [
                              for (final id in post.photoIds)
                                Photo(id: id, createdAt: post.receivedAt),
                            ];
                            return PhotoStrip(
                              photos: photos,
                              size: 88,
                              radius: AppSizes.radius12,
                              onTap: (i) => showPhotoViewer(
                                context,
                                photos,
                                initialIndex: i,
                              ),
                            );
                          },
                        ),
                      )
                    else
                      const SizedBox(height: AppSizes.space8),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    SharedPost post,
  ) async {
    final messenger = ScaffoldMessenger.of(context);

    final confirmed = await confirmDeleteSharedPost(context, post);
    if (!confirmed) return;

    try {
      await ref.read(deleteSharedPostUseCaseProvider).execute(post);
      ref.invalidate(allSharedPostsProvider);
      messenger.showSnackBar(const SnackBar(content: Text("投稿を削除しました")));
    } catch (_) {
      messenger.showSnackBar(const SnackBar(content: Text("削除できませんでした")));
    }
  }
}

/// 投稿を削除してよいか確認する
Future<bool> confirmDeleteSharedPost(
  BuildContext context,
  SharedPost post,
) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text("この投稿を削除しますか？"),
      content: Text(
        post.text.isEmpty ? "(テキストなし)" : post.text,
        maxLines: 4,
        overflow: TextOverflow.ellipsis,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text("キャンセル"),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text("削除"),
        ),
      ],
    ),
  );

  return confirmed ?? false;
}
