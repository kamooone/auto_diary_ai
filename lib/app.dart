import 'package:flutter/material.dart';
import 'app/router/app_router.dart';
import 'app/theme/theme_util.dart';
import 'l10n/app_localizations.dart';

class App extends StatelessWidget {
  const App({super.key});

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