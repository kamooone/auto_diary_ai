// app/router/app_routes.dart
import 'package:go_router/go_router.dart';
import 'package:auto_diary_ai/features/home/presentation/ui/home_screen/home_screen.dart';
import 'package:auto_diary_ai/features/home/presentation/ui/diary_create_screen/diary_create_screen.dart';

class AppRoutes {
  static const home = '/';
  static const diaryCreate = '/diary_create_screen';

  static final routes = <RouteBase>[
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
