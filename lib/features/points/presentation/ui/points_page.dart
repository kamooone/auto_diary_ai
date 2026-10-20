import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../plan/application/providers/plan_provider.dart';
import '../../application/providers/device_link_provider.dart';
import '../../application/providers/pairing_provider.dart';

/// Webのアカウント(ポイント・トークン)との紐づけ
///
/// ポイントの獲得とトークンへの交換は、すべてWebで行う。
/// アプリは、紐づけたアカウントのトークン残高を使うだけ。
class PointsPage extends ConsumerStatefulWidget {
  const PointsPage({super.key});

  @override
  ConsumerState<PointsPage> createState() => _PointsPageState();
}

class _PointsPageState extends ConsumerState<PointsPage> {
  @override
  void initState() {
    super.initState();

    // トークン残高を、最新にする
    Future.microtask(() => ref.read(usageProvider.notifier).refresh());
  }

  @override
  Widget build(BuildContext context) {
    final isLinked = ref.watch(deviceLinkProvider);

    return Scaffold(
      appBar: AppBar(title: const Text("ポイント・トークン")),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const _Description(),
          const SizedBox(height: 16),
          if (isLinked) const _LinkedCard() else const _PairingCard(),
        ],
      ),
    );
  }
}

class _Description extends StatelessWidget {
  const _Description();

  @override
  Widget build(BuildContext context) {
    return Text(
      "Webのアカウントでポイントをトークンに交換すると、AIに日記を書いてもらえる量が増えます。"
      "アカウントの作成と、ポイントの交換は、Webで行います。"
      "アカウントがなくても、アプリは毎月の枠の中で使えます。",
      style: Theme.of(context).textTheme.bodyMedium,
    );
  }
}

Future<void> _openWeb(
  BuildContext context,
  WidgetRef ref, {
  String? code,
}) async {
  final messenger = ScaffoldMessenger.of(context);

  final opened = await launchUrl(
    pointsWebUri(ref.read(pointsWebUrlProvider), code: code),
    mode: LaunchMode.externalApplication,
  ).catchError((_) => false);

  if (!opened) {
    messenger.showSnackBar(
      const SnackBar(content: Text("Webを開けませんでした")),
    );
  }
}

/// 紐づけ済み
class _LinkedCard extends ConsumerWidget {
  const _LinkedCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usage = ref.watch(usageProvider);
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.link, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text("アカウントと紐づけ済み", style: theme.textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              usage == null
                  ? "トークン残高を取得できていません"
                  : "トークン残高: ${_number(usage.tokenBalance)}",
              style: theme.textTheme.headlineSmall,
            ),
            const SizedBox(height: 4),
            Text(
              "毎月の枠を使い切ったあとに、残高から使われます。",
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () => _openWeb(context, ref),
              icon: const Icon(Icons.open_in_new),
              label: const Text("Webでポイントを交換する"),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: () => _confirmUnlink(context, ref),
              child: const Text("この端末の紐づけを解除"),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmUnlink(BuildContext context, WidgetRef ref) async {
    final agreed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("紐づけを解除しますか？"),
        content: const Text(
          "この端末では、アカウントのトークンを使えなくなります。"
          "トークンの残高は、アカウントに残ります。"
          "Webの端末一覧からも、この端末が消えます。",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text("やめる"),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text("解除する"),
          ),
        ],
      ),
    );

    if (agreed != true) return;

    await ref.read(deviceLinkProvider.notifier).unlinkFromServer();
    await ref.read(usageProvider.notifier).refresh();
  }
}

/// 未紐づけ。コードを発行して、Webで入力してもらう
class _PairingCard extends ConsumerWidget {
  const _PairingCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pairing = ref.watch(pairingProvider);
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("アカウントと紐づける", style: theme.textTheme.titleMedium),
            const SizedBox(height: 12),
            ..._content(context, ref, pairing),
          ],
        ),
      ),
    );
  }

  List<Widget> _content(
    BuildContext context,
    WidgetRef ref,
    PairingState pairing,
  ) {
    final theme = Theme.of(context);
    final notifier = ref.read(pairingProvider.notifier);

    switch (pairing.phase) {
      case PairingPhase.idle:
      case PairingPhase.expired:
      case PairingPhase.failed:
        return [
          if (pairing.phase == PairingPhase.expired)
            _message(theme, "コードの有効期限が切れました。もう一度発行してください。"),
          if (pairing.phase == PairingPhase.failed)
            _message(theme, "コードを発行できませんでした。通信を確認して、もう一度お試しください。"),
          const Text(
            "1. 下のボタンで、6桁のコードを発行します\n"
            "2. Webにログインして、コードを入力します\n"
            "3. 確認画面で、この端末であることを確かめて、紐づけます",
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: notifier.start,
            child: const Text("コードを発行する"),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () => _openWeb(context, ref),
            icon: const Icon(Icons.open_in_new),
            label: const Text("Webを開く"),
          ),
        ];

      case PairingPhase.starting:
        return const [Center(child: CircularProgressIndicator())];

      case PairingPhase.waiting:
        final code = pairing.session!.code;

        return [
          const Text("Webにログインして、このコードを入力してください。"),
          const SizedBox(height: 12),
          Center(
            child: SelectableText(
              code,
              key: const Key('pairingCode'),
              style: theme.textTheme.displayMedium?.copyWith(
                letterSpacing: 8,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
          const SizedBox(height: 4),
          Center(
            child: TextButton.icon(
              onPressed: () => Clipboard.setData(ClipboardData(text: code)),
              icon: const Icon(Icons.copy, size: 18),
              label: const Text("コードをコピー"),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "有効期限は10分です。Webで紐づけると、この画面が自動で切り替わります。"
            "自分で発行したコード以外は、入力しないでください。",
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            // 同じ端末なら、コードを入力する手間を省く
            onPressed: () => _openWeb(context, ref, code: code),
            icon: const Icon(Icons.open_in_new),
            label: const Text("Webを開いて紐づける"),
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: notifier.cancel,
            child: const Text("キャンセル"),
          ),
        ];
    }
  }

  Widget _message(ThemeData theme, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(text, style: TextStyle(color: theme.colorScheme.error)),
    );
  }
}

// 3桁ごとにカンマで区切る
String _number(int value) {
  return value.toString().replaceAllMapped(
        RegExp(r'\B(?=(\d{3})+(?!\d))'),
        (_) => ',',
      );
}
