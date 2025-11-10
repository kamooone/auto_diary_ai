import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'core/util/theme_util.dart';
import 'home/presentation/ui/diary_create_screen/diary_create_screen.dart';
import 'home/presentation/ui/home_screen/home_screen.dart';
import 'l10n/app_localizations.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => Theme(
            data: ThemeUtil.homeTheme(),
            child: HomeScreen(),
          ),
        ),

        GoRoute(
          path: '/diary_create_screen',
          builder: (context, state) => Theme(
            data: ThemeUtil.homeTheme(),
            child: const DiaryCreateScreen(),
          ),
        ),
      ],
    );

    return MaterialApp.router(
      title: AppLocalizations.of(context)?.appTitle ?? '',
      routerConfig: router,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
    );
  }
}
