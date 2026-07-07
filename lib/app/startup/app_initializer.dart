import 'package:flutter_background_service/flutter_background_service.dart';
import '../../services/background_location_service.dart';
import '../../services/notification_permission_service.dart';

class AppInitializer {
  static Future<void> initialize() async {
    // 通知許可(Android13以上)
    await NotificationPermissionService.requestPermission();

    await initializeBackgroundService();
    await FlutterBackgroundService().startService();
  }
}