import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/router/app_routes.dart';
import '../../../ai/application/providers/gemini_fallback_provider.dart';
import '../../../ai/presentation/widgets/ai_model_selector.dart';
import '../../../inquiry/application/providers/inquiry_providers.dart';
import '../../../plan/application/providers/plan_provider.dart';
import '../../../plan/domain/entities/plan_availability.dart';
import '../../../plan/presentation/widgets/usage_meter.dart';
import 'test_diary_page.dart';
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

    return Scaffold(
      appBar: AppBar(title: const Text("Settings")),
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
            onTap: paidPlanEnabled
                ? () => context.push(AppRoutes.plan)
                : null,
          ),

          // 日記を書くAIの種類(Gemini / GPT)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: AiModelSelector(),
          ),

          // Geminiが混んでいるときの、1つ性能が低いモデルの使用
          SwitchListTile(
            secondary: const Icon(Icons.shield_outlined),
            title: const Text("混んでいるときは、別のモデルを使う"),
            subtitle: const Text(
              "Geminiが混んでいて失敗したとき、1つ性能が低いモデルで書きます。"
              "文章の質が下がることがあります",
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
            title: const Text("Xの投稿"),
            subtitle: const Text("保存した投稿の削除、内容の修正、日時の変更ができます"),
            onTap: () => context.push(AppRoutes.sharedPosts),
          ),

          ListTile(
            leading: const Icon(Icons.upload_file),
            title: const Text("Xのアーカイブを取り込む"),
            subtitle: const Text("Xからダウンロードした過去の投稿を、年ごとに取り込みます"),
            onTap: () => context.push(AppRoutes.xArchiveImport),
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
              title: const Text("ホーム画面のボタン"),
              subtitle: Text(
                recording.isWidgetPinned
                    ? "表示しています"
                    : "表示すると、オン・オフをすぐに切り替えられます",
              ),
              trailing: Text(recording.isWidgetPinned ? "非表示にする" : "表示する"),
              onTap: () => recording.isWidgetPinned
                  ? _showHowToRemoveWidget()
                  : _addWidget(recording),
            ),
            const Divider(),
          ],

          // まとめ日記などを試すための、日記・Xの投稿・行動履歴を、まとめて追加・削除できるようにする
          ListTile(
            leading: const Icon(Icons.bug_report),
            title: const Text("テストデータ"),
            subtitle: const Text("日記・Xの投稿・ひとことメモ・行動履歴のテスト用のデータを、まとめて追加・削除します"),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const TestDiaryPage()),
              );
            },
          ),
        ],
      ),
    );
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
          "ホーム画面の何もないところを長押しして、ウィジェットの一覧からこのアプリのボタンを追加してください。",
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
        content: const Text("ホーム画面のボタンを長押しして、「削除」を選んでください。"),
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
