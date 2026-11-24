import 'package:flutter/material.dart';
import '../../../ads/presentation/banner_ad_view.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../../common/constants/app_colors.dart';
import '../../../../app/router/app_routes.dart';
import '../../../../common/constants/app_sizes.dart';
import '../../../../common/widgets/app_buttons.dart';
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
      bottomNavigationBar: const SafeArea(child: BannerAdView(band: true)),
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
              // Xのアーカイブを取り込んでいないと、通知は使えない。そのことと、取り込む入口を、
              // 目立つ場所に出す(スイッチが押せない理由が、分からなくならないように)
              if (!canUse) ...[
                const SizedBox(height: AppSizes.space16),
                AppCard(
                  padding: const EdgeInsets.all(AppSizes.space16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'まだ、Xのアーカイブを取り込んでいないため、通知を使えません。\n'
                        '取り込むと、毎日の通知をオンにできます。',
                        style: TextStyle(
                          fontSize: 14,
                          height: 1.8,
                          color: AppColors.text,
                        ),
                      ),
                      const SizedBox(height: AppSizes.space12),
                      SecondaryButton(
                        icon: Icons.file_download_outlined,
                        label: 'Xのアーカイブを取り込む',
                        onPressed: () =>
                            context.push(AppRoutes.xArchiveImport),
                      ),
                    ],
                  ),
                ),
              ],
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
      // 通知の準備が終わっていないと、予約できない(オンに見えて、通知が来ない状態を避ける)
      if (!notifier.isReady) {
        messenger.showSnackBar(
          const SnackBar(content: Text('通知を準備できていません。アプリを開き直してから、もう一度お試しください')),
        );
        return;
      }

      // 通知が許可されていなければ、オンにしない(端末の設定を開けるようにする)
      if (!await notifier.requestPermission()) {
        messenger.showSnackBar(
          SnackBar(
            content: const Text('通知が許可されていません。端末の設定で、通知を許可してください'),
            action: SnackBarAction(
              label: '設定を開く',
              onPressed: openAppSettings,
            ),
          ),
        );
        return;
      }

      try {
        await notifier.schedule(hour: settings.hour, minute: settings.minute);
      } catch (_) {
        messenger.showSnackBar(
          const SnackBar(content: Text('通知を設定できませんでした。もう一度お試しください')),
        );
        return;
      }
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
