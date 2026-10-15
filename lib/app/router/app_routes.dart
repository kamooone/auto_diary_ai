// app/router/app_routes.dart
import 'package:auto_diary_ai/features/calendar/presentation/ui/calendar_screen/calendar_screen.dart';
import 'package:go_router/go_router.dart';
import 'package:auto_diary_ai/features/home/presentation/ui/home_screen.dart';
import 'package:auto_diary_ai/features/setting/presentation/ui/place_search_test_page.dart';
import 'package:auto_diary_ai/features/setting/presentation/ui/settings_page.dart';
import 'package:auto_diary_ai/features/map/presentation/ui/map_page.dart';
import '../../features/calendar/presentation/ui/calendar_screen/day_posts_screen.dart';
import '../../features/diary_create/presentation/ui/diary_create_screen.dart';
import '../../features/plan/presentation/ui/plan_page.dart';
import '../../features/share/presentation/ui/share_initializer.dart';

class AppRoutes {
  static const home = '/';
  static const diaryCreate = '/diary_create_screen';
  static const settings = '/settings';
  static const plan = '/settings/plan';
  static const placeSearchTest = '/settings/place_search_test';
  static const map = '/map';
  static const calendar = '/calendar';
  static const dayPostsList = '/day_posts_list';

  static final routes = <RouteBase>[
    ShellRoute(
      builder: (context, state, child) {
        return ShareInitializer(
          child: child,
        );
      },
      routes: [
        GoRoute(
          path: home,
          builder: (context, state) => const HomeScreen(),
        ),
        GoRoute(
          path: diaryCreate,
          builder: (context, state) => const DiaryCreateScreen(),
        ),
        GoRoute(
          path: settings,
          builder: (context, state) => const SettingsPage(),
        ),
        GoRoute(
          path: plan,
          builder: (context, state) => const PlanPage(),
        ),
        GoRoute(
          path: placeSearchTest,
          builder: (context, state) => const PlaceSearchTestPage(),
        ),
        GoRoute(
          path: map,
          builder: (context, state) => const MapPage(),
        ),
        GoRoute(
          path: calendar,
          builder: (context, state) => const CalendarScreen(),
        ),
        GoRoute(
          path: dayPostsList,
          builder: (context, state) {
            final date = state.extra as DateTime;
            return DayPostsScreen(date: date);
          },
        ),
      ],
    ),
  ];
}
