import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../../application/providers/x_archive_recall_providers.dart';
import '../../domain/entities/x_archive_recall_settings.dart';

/// 過去のツイートの通知の設定(オン・オフと時刻)
class XArchiveRecallSettingsPage extends ConsumerWidget {
  const XArchiveRecallSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(xArchiveRecallSettingsProvider);
    final available = ref.watch(xArchiveRecallAvailableProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('過去のツイートの通知')),
      body: settings.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(child: Text('読み込めませんでした')),
        data: (settings) {
          final canUse = available.valueOrNull ?? false;
          return ListView(
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Text(
                  'Xのアーカイブから取り込んだツイートを、毎日お知らせします。'
                  '通知をタップすると、1年前・2年前…の今日のツイートと、'
                  'ランダムなツイートが見られます。',
                ),
              ),
              SwitchListTile(
                title: const Text('毎日通知する'),
                subtitle: canUse
                    ? null
                    : const Text('Xのアーカイブを取り込むと使えます'),
                value: settings.enabled && canUse,
                onChanged: canUse
                    ? (value) => _setEnabled(context, ref, settings, value)
                    : null,
              ),
              ListTile(
                enabled: canUse,
                title: const Text('通知する時刻'),
                subtitle: Text(_timeText(settings)),
                trailing: const Icon(Icons.chevron_right),
                onTap: canUse ? () => _pickTime(context, ref, settings) : null,
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.history),
                title: const Text('今日のツイートを見る'),
                subtitle: const Text('通知を待たずに、今すぐ開きます'),
                onTap: () => context.push(AppRoutes.xArchiveRecall),
              ),
              if (!canUse)
                ListTile(
                  leading: const Icon(Icons.upload_file),
                  title: const Text('Xのアーカイブを取り込む'),
                  onTap: () => context
                      .push(AppRoutes.xArchiveImport)
                      .then((_) => ref.invalidate(xArchiveRecallAvailableProvider)),
                ),
            ],
          );
        },
      ),
    );
  }

  static String _timeText(XArchiveRecallSettings s) =>
      '${s.hour}:${s.minute.toString().padLeft(2, '0')}';

  Future<void> _setEnabled(
    BuildContext context,
    WidgetRef ref,
    XArchiveRecallSettings settings,
    bool enabled,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final notifier = ref.read(xArchiveRecallNotifierProvider);
    final store = ref.read(xArchiveRecallSettingsStoreProvider);

    if (enabled) {
      // 通知が許可されていなければ、オンにしない
      if (!await notifier.requestPermission()) {
        messenger.showSnackBar(
          const SnackBar(content: Text('通知が許可されていません。端末の設定で、通知を許可してください')),
        );
        return;
      }
      await notifier.schedule(hour: settings.hour, minute: settings.minute);
    } else {
      await notifier.cancel();
    }
    await store.save(settings.copyWith(enabled: enabled));
    ref.invalidate(xArchiveRecallSettingsProvider);
  }

  Future<void> _pickTime(
    BuildContext context,
    WidgetRef ref,
    XArchiveRecallSettings settings,
  ) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: settings.hour, minute: settings.minute),
    );
    if (picked == null) return;

    final updated = settings.copyWith(hour: picked.hour, minute: picked.minute);
    await ref.read(xArchiveRecallSettingsStoreProvider).save(updated);
    if (updated.enabled) {
      await ref
          .read(xArchiveRecallNotifierProvider)
          .schedule(hour: updated.hour, minute: updated.minute);
    }
    ref.invalidate(xArchiveRecallSettingsProvider);
  }
}
