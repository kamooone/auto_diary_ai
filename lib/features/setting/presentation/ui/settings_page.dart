import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:auto_diary_ai/common/constants/app_colors.dart';
import 'package:auto_diary_ai/core/app_info/app_version_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/router/app_routes.dart';
import '../../../ai/application/providers/ai_model_provider.dart';
import '../../../ai/application/providers/gemini_fallback_provider.dart';
import '../../../ai/domain/entities/ai_model.dart';
import '../../../ai/presentation/widgets/ai_model_selector.dart';
import '../../../inquiry/application/providers/inquiry_providers.dart';
import '../../../plan/application/providers/plan_provider.dart';
import '../../../plan/domain/entities/plan_availability.dart';
import '../../../plan/presentation/widgets/usage_meter.dart';
import '../../../privacy/presentation/ui/privacy_policy_page.dart';
import '../../../tutorial/application/tutorial_providers.dart';
import 'test_diary_page.dart';
import '../providers/recording_settings_provider.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  // 【リリース前に、falseに戻す】ストアに出すビルドでも、「テストデータ」を出すか
  static const _showTestDataInRelease = true;

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

    return Scaffold(
      appBar: AppBar(title: const Text("設定")),
      body: ListView(
        children: [
          ListTile(
            leading: Icon(
              !paidPlanEnabled
                  ? Icons.data_usage
                  : plan.isPaid
                  ? Icons.workspace_premium
                  : Icons.person,
            ),
            title: Text(paidPlanEnabled ? "プラン" : "AIの使用量"),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 8),
              child: UsageMeter(usage: usage),
            ),
            trailing: paidPlanEnabled ? Text(plan.label) : null,
            // 有料プランがない間は、使用量はこのタイルで見えるので、画面は開かない
            // (有料プランを有効にしたときだけ、プランの画面を開く)
            onTap: paidPlanEnabled ? () => context.push(AppRoutes.plan) : null,
          ),

          // 日記を書くAIの種類(Gemini / GPT)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: AiModelSelector(),
          ),

          // Geminiが使えないときの、1つ性能が低いモデルの使用
          // (サーバーの予備のモデルはGeminiだけなので、GPTを選んでいるときは出さない)
          if (ref.watch(aiModelProvider) == AiModel.gemini)
            SwitchListTile(
              secondary: const Icon(Icons.shield_outlined),
              title: const Text("書けないときは、別のモデルで書き直す"),
              subtitle: const Text(
                "Geminiが、利用者が多いときなどに一時的に使えず、日記を書けなかったとき、"
                "少し性能が低い別のモデルで、自動で書き直します。\n"
                "日記を書けないことは減りますが、文章の質が下がることがあります",
              ),
              value: ref.watch(geminiFallbackProvider),
              onChanged: (value) =>
                  ref.read(geminiFallbackProvider.notifier).set(value),
            ),

          ListTile(
            leading: const Icon(Icons.savings),
            title: const Text("ポイント・トークン"),
            subtitle: const Text("Webのアカウントと紐づけて、使える量を増やします"),
            onTap: () => context.push(AppRoutes.points),
          ),

          ListTile(
            leading: const Icon(Icons.share),
            title: const Text("Xの投稿一覧"),
            subtitle: const Text("保存した投稿の確認、削除、内容の修正、日時の変更ができます"),
            onTap: () => context.push(AppRoutes.sharedPosts),
          ),

          ListTile(
            leading: const Icon(Icons.upload_file),
            title: const Text("Xのアーカイブを取り込む"),
            subtitle: const Text("Xからダウンロードしたアーカイブから、過去の投稿を取り込みます"),
            onTap: () => context.push(AppRoutes.xArchiveImport),
          ),

          ListTile(
            leading: const Icon(Icons.history),
            title: const Text("取り込んだXの投稿一覧"),
            subtitle: const Text("取り込んだ過去の投稿の確認、削除、内容の修正、日時の変更ができます"),
            onTap: () => context.push(AppRoutes.xArchivePosts),
          ),

          ListTile(
            leading: const Icon(Icons.notifications_active_outlined),
            title: const Text("過去のポスト(ツイート)の通知"),
            subtitle: const Text("取り込んだ過去のポスト(ツイート)を、毎日お知らせします"),
            onTap: () => context.push(AppRoutes.xArchiveRecallSettings),
          ),

          ListTile(
            leading: const Icon(Icons.mail_outline),
            title: const Text("お問い合わせ"),
            subtitle: Text(
              (ref.watch(hasUnreadReplyProvider).valueOrNull ?? false)
                  ? "新しい返信があります"
                  : "不具合のご報告や、ご要望をお送りください",
            ),
            trailing: (ref.watch(hasUnreadReplyProvider).valueOrNull ?? false)
                ? const Badge(smallSize: 18)
                : null,
            onTap: () async {
              await context.push(AppRoutes.inquiry);
              ref.invalidate(hasUnreadReplyProvider);
            },
          ),

          const Divider(),

          // オン・オフを切り替えられる端末でだけ表示する
          if (recording != null && recording.isSupported) ...[
            SwitchListTile(
              secondary: const Icon(Icons.timeline),
              title: const Text("行動履歴を記録する"),
              subtitle: const Text("オンの間だけ、位置情報と行動を記録します"),
              value: recording.isEnabled,
              onChanged: _setEnabled,
            ),
            ListTile(
              leading: const Icon(Icons.widgets),
              title: const Text("ホーム画面に、行動履歴の切り替えボタンを表示"),
              subtitle: Text(
                recording.isWidgetPinned
                    ? "ホーム画面に表示しています"
                    : "行動履歴の記録のオン・オフを、ホーム画面からすぐに切り替えられます",
              ),
              trailing: Text(recording.isWidgetPinned ? "非表示にする" : "表示する"),
              onTap: () => recording.isWidgetPinned
                  ? _showHowToRemoveWidget()
                  : _addWidget(recording),
            ),
            const Divider(),
          ],

          ListTile(
            leading: const Icon(Icons.privacy_tip_outlined),
            title: const Text("プライバシーポリシー"),
            subtitle: const Text("取得する情報と、使いみちについて"),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const PrivacyPolicyPage(),
              ),
            ),
          ),

          ListTile(
            leading: const Icon(Icons.lightbulb_outline),
            title: const Text("使い方の説明をもう一度見る"),
            subtitle: const Text("各画面の説明を、もう一度表示します"),
            onTap: _resetTutorials,
          ),

          // まとめ日記などを試すための、日記・Xの投稿・行動履歴を、まとめて追加・削除できるようにする
          // (開発のとき(デバッグ実行)だけ表示する。ストアに出すビルドでは出ない)
          // 今は、内部テストで通知の見た目を確かめるため、出している(リリース前に、falseに戻す)
          if (kDebugMode || _showTestDataInRelease)
            ListTile(
              leading: const Icon(Icons.bug_report),
              title: const Text("テストデータ"),
              subtitle: const Text(
                "日記・Xの投稿・ひとことメモ・行動履歴のテスト用のデータを、まとめて追加・削除します",
              ),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const TestDiaryPage(),
                  ),
                );
              },
            ),

          // どの版のアプリが入っているかの表示
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
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
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("使い方の説明をもう一度見ますか?"),
        content: const Text(
          "ホームに戻ると、説明が始まります。\nほかの画面の説明も、それぞれの画面を開くと、もう一度表示されます。",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text("キャンセル"),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text("見る"),
          ),
        ],
      ),
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
        .setEnabled(enabled);

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
