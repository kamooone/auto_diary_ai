import 'package:isar/isar.dart';
import '../../features/location/data/datasources/gps_location_datasource.dart';
import '../../features/location/data/datasources/isar_location_datasource.dart';
import '../../features/location/data/services/background_location_service.dart';
import '../../core/permissions/notification_permission_service.dart';

class AppInitializer {
  static Future<void> initialize(Isar isar) async {
    // 通知許可(Android13以上)
    await NotificationPermissionService.requestPermission();

    // 位置情報許可
    final gps = GpsLocationDataSource();
    final locationGranted = await gps.requestPermission();

    await initializeBackgroundService();

    // 位置情報が許可されている場合のみ記録を開始する
    if (locationGranted) {
      await startLocationRecording(
        gps: gps,
        local: IsarLocationDataSource(isar),
      );
    }
  }
}