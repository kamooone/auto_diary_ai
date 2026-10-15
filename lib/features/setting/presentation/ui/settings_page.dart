import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/router/app_routes.dart';
import '../../../plan/application/providers/plan_provider.dart';
import '../../../plan/presentation/widgets/usage_meter.dart';
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
      appBar: AppBar(
        title: const Text("Settings"),
      ),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.map),
            title: const Text("Map"),
            onTap: () {
              context.push(AppRoutes.map);
            },
          ),

          const Divider(),

          ListTile(
            leading: Icon(plan.isPaid ? Icons.workspace_premium : Icons.person),
            title: const Text("プラン"),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 8),
              child: UsageMeter(usage: usage),
            ),
            trailing: Text(plan.label),
            onTap: () => context.push(AppRoutes.plan),
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

          // 外出しなくても、訪れた場所を取得できるかを確かめられるようにする
          ListTile(
            leading: const Icon(Icons.bug_report),
            title: const Text("訪れた場所の取得テスト"),
            subtitle: const Text("地名や緯度・経度を入力して、取得できるかを確かめます"),
            onTap: () {
              context.push(AppRoutes.placeSearchTest);
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
        const SnackBar(
          content: Text("記録を開始できませんでした。位置情報を許可してください"),
        ),
      );
    }
  }

  Future<void> _addWidget(RecordingSettingsState recording) async {
    final requested = recording.isWidgetPinSupported &&
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
        content: const Text(
          "ホーム画面のボタンを長押しして、「削除」を選んでください。",
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
}
