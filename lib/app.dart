import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app/router/app_router.dart';
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
