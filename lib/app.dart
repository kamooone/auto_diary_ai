import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app/router/app_router.dart';
import 'app/router/app_routes.dart';
import 'features/x_archive/application/providers/x_archive_providers.dart';
import 'features/x_archive/application/providers/x_archive_recall_providers.dart';
import 'features/x_archive/application/services/x_archive_recall_notifier.dart';
import 'app/theme/theme_util.dart';
import 'features/inquiry/application/providers/inquiry_providers.dart';
import 'l10n/app_localizations.dart';

class App extends ConsumerStatefulWidget {
  const App({super.key});

  @override
  ConsumerState<App> createState() => _AppState();
}

class _AppState extends ConsumerState<App> {
  @override
  void initState() {
    super.initState();

    // お問い合わせの返信の通知を受ける準備(最初の画面を表示してから行う)
    WidgetsBinding.instance.addPostFrameCallback((_) => _startPush());

    // 過去のツイートの通知の準備(タップで紹介画面を開く)
    WidgetsBinding.instance.addPostFrameCallback((_) => _startRecallNotification());
  }

  Future<void> _startRecallNotification() async {
    try {
      final notifier = ref.read(xArchiveRecallNotifierProvider);
      await notifier.initialize(onTap: _openRecallIfNeeded);

      // 通知のタップでアプリが起動したときは、紹介画面を開く
      _openRecallIfNeeded(await notifier.launchPayload());

      await syncXArchiveRecallNotification(
        store: ref.read(xArchiveRecallSettingsStoreProvider),
        notifier: notifier,
        repository: ref.read(xArchiveRepositoryProvider),
      );
    } catch (_) {
      // 通知が使えない端末でも、アプリは普通に使えるようにする
    }
  }

  void _openRecallIfNeeded(String? payload) {
    if (payload != XArchiveRecallNotifier.payload) return;
    AppRouter.router.push(AppRoutes.xArchiveRecall);
  }

  Future<void> _startPush() async {
    try {
      await ref.read(pushRegistrarProvider).start();
    } catch (_) {
      // 通知が使えない端末でも、アプリは普通に使えるようにする
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      routerConfig: AppRouter.router, // ルーティング設定
      theme: ThemeUtil.appTheme(), // アプリ全体のテーマ設定
      onGenerateTitle: (context) => AppLocalizations.of(context)?.appTitle ?? '', // アプリタイトル（ローカライズ対応）
      localizationsDelegates: AppLocalizations.localizationsDelegates, // 多言語対応のデリゲート設定
      supportedLocales: AppLocalizations.supportedLocales, // 対応している言語一覧
    );
  }
}
