import 'package:flutter/rendering.dart' show ScrollCacheExtent;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/router/app_routes.dart';
import '../../../../core/app_info/install_date_provider.dart';
import '../../../ads/presentation/banner_ad_view.dart';
import '../../../tutorial/application/tutorial_providers.dart';
import '../../../tutorial/domain/tutorial_step.dart';
import '../../../tutorial/presentation/tutorial_runner.dart';
import '../../../../common/widgets/app_buttons.dart';
import '../../../../common/widgets/app_card.dart';
import '../../../../common/widgets/app_text_field.dart';
import '../../../../common/widgets/section_title.dart';
import '../../../../common/widgets/select_row.dart';
import '../providers/diary_create_provider.dart';
import 'widgets/diary_period_text.dart';
import 'diary_ai_screen.dart';
import 'widgets/photo_selection_card.dart';

/// 日記を自分で書く画面
/// AIに書いてもらう場合は、ここからAI用の画面へ進む
class DiaryCreateScreen extends ConsumerStatefulWidget {
  const DiaryCreateScreen({super.key});

  @override
  ConsumerState<DiaryCreateScreen> createState() => _DiaryCreateScreenState();
}

class _DiaryCreateScreenState extends ConsumerState<DiaryCreateScreen> {
  // チュートリアルで明るくする部品
  final _dateKey = GlobalKey();
  final _aiKey = GlobalKey();
  final _summaryKey = GlobalKey();

  // この画面のチュートリアルの印(見たかどうかを覚えるときの名前)
  static const _tutorialId = 'diary_create';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _showTutorialOnce());
  }

  // 自分で日記を書く、AI、振り返りの順に説明する(初めて表示したときだけ)
  Future<void> _showTutorialOnce() async {
    final store = ref.read(tutorialSeenStoreProvider);
    if (await store.hasSeen(_tutorialId)) return;
    if (!mounted) return;

    await showTutorial(context, [
      // 日付・タイトルと本文・写真・保存は、基本的な操作なので、一番上の日付だけを光らせて、1ページで説明する
      TutorialStep(
        target: _dateKey,
        title: "自分で日記を書く",
        body: "日記の日付を選び、タイトルと本文を書いて、写真を添えて、保存します。",
      ),
      TutorialStep(
        target: _aiKey,
        title: "AIに日記を書いてもらう",
        body: "AIに日記を書いてもらう画面に移ります。行動履歴や写真、Xの投稿、ひとことなどを選ぶと、AIが日記を作成します。",
        bubbleAbove: true,
      ),
      TutorialStep(
        target: _summaryKey,
        title: "振り返りを作成する",
        body: "振り返りの作成画面に移ります。作成済みの複数の日記から、ブログ風や出来事の一覧などの形で、振り返りを作成できます。",
        bubbleAbove: true,
      ),
    ]);

    await store.markSeen(_tutorialId);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(diaryCreateProvider);
    final viewModel = ref.read(diaryCreateProvider.notifier);

    final date = state.startDate;

    return Scaffold(
      appBar: AppBar(title: const Text("日記作成")),
      // 画面の下部に、バナー広告を表示する(読み込めたときだけ、白い帯で出る)
      bottomNavigationBar: const SafeArea(child: BannerAdView(band: true)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
        // 画面の外にある部品も、チュートリアルで場所を取れるよう、先に作っておく
        scrollCacheExtent: const ScrollCacheExtent.pixels(3000),
        children: [
          // ---------- いつの日記か
          AppCard(
            key: _dateKey,
            child: SelectRow(
              icon: Icons.calendar_today_outlined,
              label: "日記の日付",
              value: dateWithWeekday(date),
              onTap: () async {
                final now = DateTime.now();
                final installDate = ref.read(installDateProvider);

                // アプリを使い始めた日から今日までの1日を選ぶ
                final selected = await showDatePicker(
                  initialEntryMode: DatePickerEntryMode.calendarOnly,
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
          const SizedBox(height: 24),

          // ---------- 日記の内容
          AppTextField(
            label: "タイトル",
            hintText: "今日のできごとをひとことで",
            onChanged: viewModel.setInputTitle,
          ),
          const SizedBox(height: 16),
          AppTextField(
            label: "本文",
            hintText: "今日あったこと、感じたことを自由に",
            height: 220,
            onChanged: viewModel.setMainContent,
          ),
          const SizedBox(height: 24),

          // 自分で書く日記には、撮影日に関係なく写真を添えられる
          PhotoSelectionCard(
            photos: state.selectedPhotos,
            onChanged: viewModel.setSelectedPhotos,
          ),
          const SizedBox(height: 24),

          // ---------- 保存
          PrimaryButton(
            icon: Icons.save_outlined,
            label: "保存する",
            // 本文が空の日記は保存できない
            onPressed: state.content.trim().isEmpty
                ? null
                : () async {
                    final messenger = ScaffoldMessenger.of(context);
                    final navigator = Navigator.of(context);

                    final saved = await viewModel.saveManualDiary();

                    messenger.showSnackBar(
                      SnackBar(
                        content: Text(saved ? "日記を保存しました" : "保存に失敗しました"),
                      ),
                    );

                    if (saved) {
                      navigator.pop();
                    }
                  },
          ),
          const SizedBox(height: 24),

          // ---------- AIの力をかりる
          const SectionTitle("AIの力をかりる"),
          // AIに書いてもらう場合は専用の画面へ
          SecondaryButton(
            key: _aiKey,
            icon: Icons.auto_awesome,
            label: "AIに日記を書いてもらう",
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const DiaryAiScreen()),
              );
            },
          ),
          const SizedBox(height: 12),

          // 作成済みの日記をまとめる場合は専用の画面へ
          SecondaryButton(
            key: _summaryKey,
            icon: Icons.menu_book_outlined,
            label: "振り返りを作成する",
            onPressed: () => context.push(AppRoutes.summaryDiary),
          ),
        ],
      ),
    );
  }
}
