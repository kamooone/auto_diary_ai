import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../common/constants/app_colors.dart';
import '../../../../common/constants/app_sizes.dart';
import '../../../../common/widgets/app_card.dart';
import '../../../../common/widgets/select_row.dart';
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
      appBar: AppBar(title: const Text('過去のポスト(ツイート)の通知')),
      body: settings.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(child: Text('読み込めませんでした')),
        data: (settings) {
          final canUse = available.valueOrNull ?? false;
          return ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSizes.space16,
              20,
              AppSizes.space16,
              AppSizes.space24,
            ),
            children: [
              AppCard(
                padding: const EdgeInsets.all(AppSizes.space16),
                child: const Text(
                  'Xのアーカイブから取り込んだポスト(ツイート)を、毎日お知らせします。\n'
                  '通知をタップすると、1年前・2年前…の今日のポスト(ツイート)と、'
                  'ランダムなポスト(ツイート)が見られます。',
                  style: TextStyle(
                    fontSize: 15,
                    height: 1.8,
                    color: AppColors.text,
                  ),
                ),
              ),
              const SizedBox(height: AppSizes.space24),
              AppCard(
                child: Column(
                  children: [
                    SwitchRow(
                      icon: Icons.notifications_none,
                      label: '毎日通知する',
                      subtitle: canUse ? null : 'Xのアーカイブを取り込むと使えます',
                      value: settings.enabled && canUse,
                      onChanged: canUse
                          ? (value) =>
                                _setEnabled(context, ref, settings, value)
                          : null,
                    ),
                    const RowDivider(),
                    SelectRow(
                      icon: Icons.schedule,
                      label: '通知する時刻',
                      value: _timeText(settings),
                      enabled: canUse,
                      onTap: canUse
                          ? () => _pickTime(context, ref, settings)
                          : null,
                    ),
                  ],
                ),
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
