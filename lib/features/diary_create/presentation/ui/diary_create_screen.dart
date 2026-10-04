import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/app_info/install_date_provider.dart';
import '../../../location/domain/entities/timeline_item.dart';
import '../../../share/domain/entities/shared_post.dart';
import '../../application/providers/diary_usecase_providers.dart';
import '../../domain/entities/photo.dart';
import '../providers/diary_create_provider.dart';
import 'diary_result_screen.dart';
import 'photo_picker_page.dart';
import 'post_select_page.dart';
import 'timeline_select_page.dart';
import 'widgets/photo_thumbnail.dart';

/// 日記を書いてもらうための情報を入力・選択する画面
class DiaryCreateScreen extends ConsumerWidget {
  const DiaryCreateScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(diaryCreateProvider);
    final viewModel = ref.read(diaryCreateProvider.notifier);
    final plan = ref.watch(diaryPlanProvider);

    final date = state.startDate;

    return Scaffold(
      appBar: AppBar(title: const Text("AI日記作成")),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ---------- いつの日記か
          Card(
            child: ListTile(
              leading: const Icon(Icons.calendar_today),
              title: const Text("日記の日付"),
              subtitle: Text("${date.year}年${date.month}月${date.day}日"),
              trailing: const Icon(Icons.chevron_right),
              onTap: () async {
                final now = DateTime.now();
                final installDate = ref.read(installDateProvider);

                // アプリを使い始めた日から今日までの1日を選ぶ
                final selected = await showDatePicker(
                  context: context,
                  initialDate: date,
                  firstDate: DateTime(
                    installDate.year,
                    installDate.month,
                    installDate.day,
                  ),
                  lastDate: DateTime(now.year, now.month, now.day),
                );

                if (selected != null) {
                  viewModel.setDate(selected);
                }
              },
            ),
          ),
          const SizedBox(height: 12),

          // ---------- 自分で書く内容
          TextField(
            decoration: const InputDecoration(
              labelText: "タイトル",
              border: OutlineInputBorder(),
            ),
            onChanged: viewModel.setInputTitle,
          ),
          const SizedBox(height: 8),
          TextField(
            decoration: const InputDecoration(
              labelText: "本文",
              border: OutlineInputBorder(),
              alignLabelWithHint: true,
            ),
            keyboardType: TextInputType.multiline,
            minLines: 4,
            maxLines: 8,
            onChanged: viewModel.setMainContent,
          ),
          const SizedBox(height: 16),

          // ---------- AIに渡す情報
          Text(
            "AIに渡す情報",
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 4),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.photo_library),
                  title: const Text("写真"),
                  subtitle: Text(
                    "${state.selectedPhotos.length}枚を選択中（最大${plan.maxPhotos}枚）",
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () async {
                    final photos =
                        await Navigator.of(context).push<List<Photo>>(
                      MaterialPageRoute(
                        fullscreenDialog: true,
                        builder: (context) => PhotoPickerPage(
                          initialSelection: state.selectedPhotos,
                          maxSelection: plan.maxPhotos,
                          from: state.startDate,
                          // 対象期間の最終日の終わりまで
                          to: DateTime(
                            state.endDate.year,
                            state.endDate.month,
                            state.endDate.day + 1,
                          ),
                        ),
                      ),
                    );

                    if (photos != null) {
                      viewModel.setSelectedPhotos(photos);
                    }
                  },
                ),
                if (state.selectedPhotos.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: SizedBox(
                      height: 72,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: state.selectedPhotos.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(width: 6),
                        itemBuilder: (context, index) {
                          final photo = state.selectedPhotos[index];

                          return SizedBox(
                            key: ValueKey(photo.id),
                            width: 72,
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: PhotoThumbnail(photo: photo),
                                ),
                                Positioned(
                                  top: 2,
                                  right: 2,
                                  child: GestureDetector(
                                    onTap: () =>
                                        viewModel.removeSelectedPhoto(photo),
                                    child: const CircleAvatar(
                                      radius: 10,
                                      backgroundColor: Colors.black54,
                                      child: Icon(
                                        Icons.close,
                                        size: 14,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.share),
                  title: const Text("Xの投稿"),
                  subtitle: Text(
                    _selectionText(
                      isLoading: state.isLoadingSources,
                      total: state.posts.length,
                      selected: state.selectedPosts.length,
                      emptyText: "この日の投稿はありません",
                    ),
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  enabled: state.posts.isNotEmpty,
                  onTap: () async {
                    final posts =
                        await Navigator.of(context).push<List<SharedPost>>(
                      MaterialPageRoute(
                        fullscreenDialog: true,
                        builder: (context) => PostSelectPage(
                          posts: state.posts,
                          initialSelection: state.selectedPosts,
                        ),
                      ),
                    );

                    if (posts != null) {
                      viewModel.setSelectedPosts(posts);
                    }
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.timeline),
                  title: const Text("行動履歴"),
                  subtitle: Text(
                    _selectionText(
                      isLoading: state.isLoadingSources,
                      total: state.timeline.length,
                      selected: state.selectedTimeline.length,
                      emptyText: "この日の行動履歴はありません",
                    ),
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  enabled: state.timeline.isNotEmpty,
                  onTap: () async {
                    final items =
                        await Navigator.of(context).push<List<TimelineItem>>(
                      MaterialPageRoute(
                        fullscreenDialog: true,
                        builder: (context) => TimelineSelectPage(
                          items: state.timeline,
                          initialSelection: state.selectedTimeline,
                        ),
                      ),
                    );

                    if (items != null) {
                      viewModel.setSelectedTimeline(items);
                    }
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // ---------- 生成
          ElevatedButton(
            // 読み込みが終わるまでは、選択内容が確定しないため押せないようにする
            onPressed: state.isLoadingSources
                ? null
                : () {
                    viewModel.generateDiary();

                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const DiaryResultScreen(),
                      ),
                    );
                  },
            child: const Text("AIに日記を書いてもらう"),
          ),
        ],
      ),
    );
  }

  String _selectionText({
    required bool isLoading,
    required int total,
    required int selected,
    required String emptyText,
  }) {
    if (isLoading) return "読み込み中…";
    if (total == 0) return emptyText;
    return "$total件中$selected件を選択中";
  }
}
