import 'package:flutter/material.dart';
import 'package:auto_diary_ai/common/constants/app_colors.dart';
import 'package:auto_diary_ai/common/constants/app_sizes.dart';
import 'package:auto_diary_ai/common/widgets/app_card.dart';
import 'package:auto_diary_ai/common/widgets/confirm_dialog.dart';
import 'package:auto_diary_ai/common/widgets/section_title.dart';
import 'package:auto_diary_ai/common/widgets/select_row.dart' show RowDivider;
import 'package:auto_diary_ai/core/app_info/app_version_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/router/app_routes.dart';
import '../../../ai/presentation/widgets/ai_select_card.dart';
import '../../../inquiry/application/providers/inquiry_providers.dart';
import '../../../plan/application/providers/plan_provider.dart';
import '../../../plan/domain/entities/plan_availability.dart';
import '../../../location/presentation/ui/activity_permission_explanation.dart';
import '../../../privacy/presentation/ui/privacy_policy_page.dart';
import '../../../tutorial/application/tutorial_providers.dart';
import 'widgets/settings_row.dart';
import '../providers/recording_settings_provider.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  // ウィジェットで切り替えたり、ホーム画面に追加したりした結果を、戻ってきたときに反映する
  late final AppLifecycleListener _lifecycleListener;

  @override
  void initState() {
    super.initState();

    // 今月の使用量を取得する
    Future.microtask(() => ref.read(usageProvider.notifier).refresh());

    _lifecycleListener = AppLifecycleListener(
      onResume: () {
        ref.invalidate(recordingSettingsProvider);
        ref.read(usageProvider.notifier).refresh();
      },
    );
  }

  @override
  void dispose() {
    _lifecycleListener.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final recording = ref.watch(recordingSettingsProvider).valueOrNull;
    final plan = ref.watch(planTypeProvider);
    final usage = ref.watch(usageProvider);

    final hasUnread = ref.watch(hasUnreadReplyProvider).valueOrNull ?? false;

    return Scaffold(
      appBar: AppBar(title: const Text("設定")),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSizes.space16,
          AppSizes.space16,
          AppSizes.space16,
          AppSizes.space24,
        ),
        children: [
          // ---------- AI
          const SectionTitle("AI"),
          // 日記を書くAIの種類(Gemini / GPT)と、今月の使用量
          AiSelectCard(usage: usage),
          // 有料プランがない間は、使用量は上のカードで見えるので、プランの画面は開かない
          if (paidPlanEnabled) ...[
            const SizedBox(height: AppSizes.space12),
            AppCard(
              child: SettingsRow(
                icon: Icons.workspace_premium,
                title: "プラン",
                trailing: Text(
                  plan.label,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.navy,
                  ),
                ),
                onTap: () => context.push(AppRoutes.plan),
              ),
            ),
          ],
          const SizedBox(height: AppSizes.space16),
          AppCard(
            child: Column(
              children: [
                SettingsRow(
                  icon: Icons.savings_outlined,
                  title: "ポイント・ゲーム",
                  subtitle: "ゲームで貯めたポイントは、トークンに交換できます",
                  onTap: () => context.push(AppRoutes.points),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSizes.space24),

          // ---------- Xの投稿
          const SectionTitle("Xの投稿"),
          AppCard(
            child: Column(
              children: [
                SettingsRow(
                  icon: Icons.format_list_bulleted,
                  title: "Xの投稿一覧",
                  subtitle: "保存した投稿の確認、削除、内容の修正、日時の変更ができます",
                  onTap: () => context.push(AppRoutes.sharedPosts),
                ),
                const RowDivider(),
                SettingsRow(
                  icon: Icons.upload_file,
                  title: "Xのアーカイブを取り込む",
                  subtitle: "Xからダウンロードしたアーカイブから、過去の投稿を取り込みます",
                  onTap: () => context.push(AppRoutes.xArchiveImport),
                ),
                const RowDivider(),
                SettingsRow(
                  icon: Icons.history,
                  title: "取り込んだXの投稿一覧",
                  subtitle: "取り込んだ過去の投稿の確認、削除、内容の修正、日時の変更ができます",
                  onTap: () => context.push(AppRoutes.xArchivePosts),
                ),
                const RowDivider(),
                SettingsRow(
                  icon: Icons.notifications_none,
                  title: "過去のポスト(ツイート)の通知",
                  subtitle: "取り込んだ過去のポスト(ツイート)を、毎日お知らせします",
                  onTap: () => context.push(AppRoutes.xArchiveRecallSettings),
                ),
              ],
            ),
          ),

          // ---------- 行動履歴(オン・オフを切り替えられる端末でだけ表示する)
          if (recording != null && recording.isSupported) ...[
            const SizedBox(height: AppSizes.space24),
            const SectionTitle("行動履歴"),
            AppCard(
              child: Column(
                children: [
                  SettingsRow(
                    icon: Icons.timeline,
                    title: "行動履歴を記録する",
                    subtitle: "オンの間だけ、位置情報と行動を記録します",
                    trailing: Switch(
                      value: recording.isEnabled,
                      onChanged: _setEnabled,
                    ),
                    onTap: () => _setEnabled(!recording.isEnabled),
                  ),
                  const RowDivider(),
                  SettingsRow(
                    icon: Icons.widgets_outlined,
                    title: "ホーム画面に、行動履歴の切り替えボタンを表示",
                    subtitle: recording.isWidgetPinned
                        ? "ホーム画面に表示しています"
                        : "行動履歴の記録のオン・オフを、ホーム画面からすぐに切り替えられます",
                    extra: SettingsPillButton(
                      label: recording.isWidgetPinned ? "非表示にする" : "表示する",
                      onPressed: () => recording.isWidgetPinned
                          ? _showHowToRemoveWidget()
                          : _addWidget(recording),
                    ),
                    onTap: () => recording.isWidgetPinned
                        ? _showHowToRemoveWidget()
                        : _addWidget(recording),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: AppSizes.space24),

          // ---------- サポート
          const SectionTitle("サポート"),
          AppCard(
            child: Column(
              children: [
                SettingsRow(
                  icon: Icons.mail_outline,
                  title: "お問い合わせ",
                  subtitle: hasUnread ? "新しい返信があります" : "不具合のご報告や、ご要望をお送りください",
                  trailing: hasUnread ? const Badge(smallSize: 18) : null,
                  onTap: () async {
                    await context.push(AppRoutes.inquiry);
                    ref.invalidate(hasUnreadReplyProvider);
                  },
                ),
                const RowDivider(),
                SettingsRow(
                  icon: Icons.privacy_tip_outlined,
                  title: "プライバシーポリシー",
                  subtitle: "取得する情報と、使いみちについて",
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const PrivacyPolicyPage(),
                    ),
                  ),
                ),
                const RowDivider(),
                SettingsRow(
                  icon: Icons.lightbulb_outline,
                  title: "使い方の説明をもう一度見る",
                  subtitle: "各画面の説明を、もう一度表示します",
                  onTap: _resetTutorials,
                ),
              ],
            ),
          ),

          // どの版のアプリが入っているかの表示
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSizes.space24),
            child: Center(
              child: Text(
                "バージョン ${ref.watch(appVersionProvider).valueOrNull ?? ""}",
                style: const TextStyle(fontSize: 12, color: AppColors.textSub),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _resetTutorials() async {
    final confirmed = await showConfirmDialog(
      context,
      icon: Icons.lightbulb_outline,
      title: "使い方の説明を\nもう一度見ますか？",
      message: "ホームに戻ると、説明が始まります。\nほかの画面の説明も、それぞれの画面を開くと、もう一度表示されます。",
      confirmLabel: "見る",
    );
    if (confirmed != true || !mounted) return;

    await ref.read(tutorialSeenStoreProvider).clearAll();
    if (!mounted) return;

    // ホームに戻ると、ホームの説明がすぐに始まる
    context.pop();
  }

  Future<void> _setEnabled(bool enabled) async {
    final messenger = ScaffoldMessenger.of(context);

    final succeeded = await ref
        .read(recordingSettingsProvider.notifier)
        .setEnabled(
          enabled,
          // 身体活動の許可の前に、何のために使うのかを説明する
          explainActivity: () async =>
              mounted && await showActivityPermissionExplanation(context),
        );

    if (!succeeded) {
      messenger.showSnackBar(
        const SnackBar(content: Text("記録を開始できませんでした。位置情報を許可してください")),
      );
    }
  }

  Future<void> _addWidget(RecordingSettingsState recording) async {
    final requested =
        recording.isWidgetPinSupported &&
        await ref.read(recordingSettingsProvider.notifier).requestPinWidget();

    if (requested || !mounted) return;

    // ホームアプリによっては、アプリから追加を求められない
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        scrollable: true,
        title: const Text("ホーム画面から追加してください"),
        content: const Text(
          "ホーム画面の何もないところを長押しして、ウィジェットの一覧から、このアプリの「行動履歴」のボタンを追加してください。",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  // ホーム画面のウィジェットは、アプリからは取り除けない
  Future<void> _showHowToRemoveWidget() {
    return showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        scrollable: true,
        title: const Text("ホーム画面から削除してください"),
        content: const Text("ホーム画面の行動履歴のオン・オフのボタンを長押しして、「削除」を選んでください。"),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }
}
