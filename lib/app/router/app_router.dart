// app/router/app_router.dart
import 'package:go_router/go_router.dart';
import 'app_routes.dart';

class AppRouter {
  static final router = GoRouter(
    initialLocation: AppRoutes.home, // 起動時の初期画面
    routes: AppRoutes.routes, // URLと画面の対応表
  );
}