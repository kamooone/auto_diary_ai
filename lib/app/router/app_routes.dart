// app/router/app_routes.dart
import 'package:go_router/go_router.dart';
import 'package:auto_diary_ai/features/home/presentation/ui/home_screen/home_screen.dart';
import 'package:auto_diary_ai/features/home/presentation/ui/diary_create_screen/diary_create_screen.dart';
import 'package:auto_diary_ai/features/setting/settings_page.dart';
import 'package:auto_diary_ai/features/map/presentation/ui/map_page.dart';

class AppRoutes {
  static const home = '/';
  static const diaryCreate = '/diary_create_screen';
  static const settings = '/settings';
  static const map = '/map';

  static final routes = <RouteBase>[
    GoRoute(
      path: settings,
      builder: (context, state) => const SettingsPage(),
    ),
    GoRoute(
      path: map,
      builder: (context, state) => const MapPage(),
    ),
    GoRoute(
      path: home,
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: diaryCreate,
      builder: (context, state) => const DiaryCreateScreen(),
    ),
  ];
}
