// app/router/app_routes.dart
import 'package:go_router/go_router.dart';
import 'package:auto_diary_ai/features/home/presentation/ui/home_screen.dart';
import 'package:auto_diary_ai/features/setting/presentation/ui/settings_page.dart';
import 'package:auto_diary_ai/features/map/presentation/ui/map_page.dart';
import '../../features/calendar/presentation/ui/calendar_screen.dart';
import '../../features/diary_create/presentation/ui/diary_create_screen.dart';
import '../../features/diary_create/presentation/ui/summary_diary_screen.dart';
import '../../features/inquiry/presentation/ui/inquiry_page.dart';
import '../../features/plan/presentation/ui/plan_page.dart';
import '../../features/points/presentation/ui/points_page.dart';
import '../../features/share/presentation/ui/share_initializer.dart';
import '../../features/share/presentation/ui/shared_post_list_screen.dart';
import '../../features/x_archive/presentation/ui/x_archive_import_page.dart';
import '../../features/x_archive/presentation/ui/x_archive_post_list_page.dart';
import '../../features/x_archive/presentation/ui/x_archive_recall_page.dart';
import '../../features/x_archive/presentation/ui/x_archive_recall_settings_page.dart';

class AppRoutes {
  static const home = '/';
  static const diaryCreate = '/diary_create_screen';
  static const summaryDiary = '/summary_diary_screen';
  static const calendar = '/calendar';
  static const settings = '/settings';
  static const plan = '/settings/plan';
  static const points = '/settings/points';
  static const sharedPosts = '/settings/shared_posts';
  static const xArchiveImport = '/settings/x_archive_import';
  static const xArchivePosts = '/settings/x_archive_posts';
  static const xArchiveRecall = '/x_archive_recall';
  static const xArchiveRecallSettings = '/settings/x_archive_recall';
  static const inquiry = '/settings/inquiry';
  static const map = '/map';

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
          path: summaryDiary,
          builder: (context, state) => const SummaryDiaryScreen(),
        ),
        GoRoute(
          path: calendar,
          builder: (context, state) => const CalendarScreen(),
        ),
        GoRoute(
          path: settings,
          builder: (context, state) => const SettingsPage(),
        ),
        GoRoute(
          path: sharedPosts,
          builder: (context, state) => const SharedPostListScreen(),
        ),
        GoRoute(
          path: xArchiveRecall,
          builder: (context, state) => XArchiveRecallPage(
            date: DateTime.tryParse(state.uri.queryParameters['date'] ?? ''),
          ),
        ),
        GoRoute(
          path: xArchiveRecallSettings,
          builder: (context, state) => const XArchiveRecallSettingsPage(),
        ),
        GoRoute(
          path: xArchivePosts,
          builder: (context, state) => const XArchivePostListPage(),
        ),
        GoRoute(
          path: xArchiveImport,
          builder: (context, state) => const XArchiveImportPage(),
        ),
        GoRoute(
          path: plan,
          builder: (context, state) => const PlanPage(),
        ),
        GoRoute(
          path: points,
          builder: (context, state) => const PointsPage(),
        ),
        GoRoute(
          path: inquiry,
          builder: (context, state) => const InquiryPage(),
        ),
        GoRoute(
          path: map,
          builder: (context, state) => const MapPage(),
        ),
      ],
    ),
  ];
}
